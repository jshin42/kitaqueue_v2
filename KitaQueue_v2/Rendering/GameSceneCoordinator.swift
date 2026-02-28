import SwiftUI
import SpriteKit

/// @Observable bridge between SwiftUI and SpriteKit.
/// Owns the GameSimulation and synchronizes state with the scene.
/// Events from simulation are processed via `processEvents()` called from GameScene.update().
@MainActor @Observable
final class GameSceneCoordinator {

    // MARK: - Published State (SwiftUI reads these)

    var bankedCount: Int = 0
    var totalShuriken: Int = 24
    var operatorsUsed: Int = 0
    var parThreshold: Int = 6
    var starRating: Int = 0
    var currentLevel: Int = 1
    var attemptNumber: Int = 1
    var failReason: FailReason? = nil
    var nearMissBanked: Int? = nil
    var nearMissOverflowMargin: Int? = nil

    enum Phase: Equatable {
        case idle, preview, playing, tutorialPaused, paused, won, failed
    }
    var gamePhase: Phase = .idle

    // MARK: - Internal

    private(set) var simulation: GameSimulation?
    private(set) var scene: GameScene?
    private var levelData: LevelData?

    // MARK: - Scene

    func makeScene(size: CGSize) -> GameScene {
        let s = GameScene(size: size)
        s.scaleMode = .resizeFill
        s.coordinator = self
        self.scene = s
        return s
    }

    // MARK: - Level Lifecycle

    func startLevel(id: Int) {
        currentLevel = id
        bankedCount = 0
        operatorsUsed = 0
        starRating = 0
        attemptNumber = 1
        failReason = nil
        nearMissBanked = nil
        nearMissOverflowMargin = nil
        gamePhase = .preview

        let data = LevelLoader.loadOrGenerate(id: id)
        self.levelData = data
        self.totalShuriken = data.totalShuriken
        self.parThreshold = data.threeStarMaxOps

        let sim = GameSimulation(levelData: data)
        self.simulation = sim

        scene?.setupBoard()
    }

    func retry() {
        simulation?.reset()
        bankedCount = 0
        operatorsUsed = 0
        starRating = 0
        failReason = nil
        nearMissBanked = nil
        nearMissOverflowMargin = nil
        attemptNumber += 1
        gamePhase = .preview
        scene?.clearDynamicNodes()
        scene?.setupBoard()
    }

    func nextLevel() {
        startLevel(id: currentLevel + 1)
    }

    // MARK: - Actions

    func undoLastOperator() {
        guard let sim = simulation else { return }
        let input = PlayerInput.undo(timestep: sim.state.timestep)
        if sim.applyInput(input) {
            scene?.removeLastOperatorNode()
            operatorsUsed = sim.state.totalOperatorsPlaced
            scene?.updateParBadge(used: operatorsUsed, threshold: parThreshold)
        }
    }

    func pauseGame() {
        simulation?.pause()
        gamePhase = .paused
    }

    func resumeGame() {
        simulation?.resume()
        gamePhase = .playing
    }

    func resumeFromTutorial() {
        simulation?.resumeFromTutorial()
        gamePhase = .playing
    }

    // MARK: - Fix It Resume

    func resumeFromFixIt() {
        guard let sim = simulation,
              let checkpoint = sim.checkpointManager.restoreCheckpoint()
        else { return }

        var restored = checkpoint

        switch failReason {
        case .overflow(let lane):
            CheckpointManager.applyOverflowFix(&restored, lane: lane)
        case .misbank:
            CheckpointManager.applyMisbankFix(&restored)
        case .none:
            return
        }

        sim.restoreState(restored)

        // Sync coordinator state
        bankedCount = restored.bankedCount
        operatorsUsed = restored.totalOperatorsPlaced
        failReason = nil
        nearMissBanked = nil
        nearMissOverflowMargin = nil
        gamePhase = .playing

        // Refresh scene
        scene?.clearDynamicNodes()
        scene?.setupBoard()
    }

    // MARK: - Progression Save

    func saveWinProgression() {
        var progression = PersistenceService.shared.loadProgression()

        // Update best stars
        let previous = progression.bestStars[currentLevel] ?? 0
        if starRating > previous {
            progression.bestStars[currentLevel] = starRating
        }

        // Award coins and XP
        let coins = StarCalculator.coins(stars: starRating)
        let xp = StarCalculator.xp(stars: starRating)
        progression.totalCoins += coins
        progression.totalXP += xp

        // Advance current level if this was the frontier
        if currentLevel >= progression.currentLevel {
            progression.currentLevel = currentLevel + 1
            progression.completedLevels = max(progression.completedLevels, currentLevel)
        }

        // Milestone tokens: +1 every 10 levels completed
        let prevMilestones = max(0, progression.completedLevels - 1) / GameConstants.levelsPerMilestoneToken
        let newMilestones = progression.completedLevels / GameConstants.levelsPerMilestoneToken
        if newMilestones > prevMilestones {
            progression.totalTokens += (newMilestones - prevMilestones)
        }

        PersistenceService.shared.saveProgression(progression)
    }

    // MARK: - Touch -> Operator Placement

    func attemptPlacement(row: Int, slot: BoundarySlot) {
        guard let sim = simulation else { return }

        let input = PlayerInput.place(row: row, slot: slot, timestep: sim.state.timestep)
        if sim.applyInput(input) {
            // Success - visual + feedback
            let layout = scene.map { LayoutCalculator(sceneSize: $0.size) }
            if let layout = layout {
                scene?.addOperatorNode(
                    id: sim.state.operators.last!.id,
                    row: row,
                    slot: slot,
                    position: layout.operatorPosition(row: row, slot: slot.rawValue),
                    size: layout.operatorSize
                )
            }
            operatorsUsed = sim.state.totalOperatorsPlaced
            scene?.updateParBadge(used: operatorsUsed, threshold: parThreshold)

            HapticManager.shared.snapConfirm()
            SoundManager.shared.playSlashPlace()
        } else {
            // Cap reached
            HapticManager.shared.error()
        }
    }

    func canPlace(row: Int, slot: BoundarySlot) -> Bool {
        simulation?.canPlaceOperator(row: row, slot: slot) ?? false
    }

    /// Update toggle gate visual indicator to show the current allowed color
    private func updateToggleGateIndicator(lane: Int, row: Int) {
        guard let sim = simulation,
              let gate = sim.levelData.gates.first(where: { $0.type == .toggle && $0.lane == lane && $0.row == row })
        else { return }

        let gateKey = "\(lane)_\(row)"
        let encounters = sim.state.gateEncounters[gateKey, default: 0]
        if let color = GateProcessor.toggleAllowedColor(gate: gate, encounterCount: encounters) {
            scene?.updateToggleGateIndicator(lane: lane, row: row, color: color)
        }
    }

    // MARK: - Event Processing (called from GameScene.update on main thread)

    func processEvents(_ events: [SimulationEvent]) {
        for event in events {
            handleEvent(event)
        }
    }

    private func handleEvent(_ event: SimulationEvent) {
        switch event {
        case .shurikenSpawned(let id, let color, let lane):
            scene?.spawnShurikenNode(id: id, color: color, lane: lane)

        case .shurikenBanked(_, let bankColor):
            bankedCount = simulation?.state.bankedCount ?? bankedCount
            scene?.updateCounter(banked: bankedCount, total: totalShuriken)
            scene?.flashBank(lane: bankColor.laneIndex)
            HapticManager.shared.bankTick()
            SoundManager.shared.playBankTick()

        case .shurikenMisbanked(_, _, _):
            bankedCount = simulation?.state.bankedCount ?? bankedCount
            failReason = simulation?.state.failReason
            nearMissBanked = bankedCount
            gamePhase = .failed
            HapticManager.shared.failThud()
            SoundManager.shared.playFailThud()
            scene?.showFailFlash()

        case .operatorTriggered(let row, let slot, _, let remaining):
            scene?.triggerOperatorNode(row: row, slot: slot, remainingCharges: remaining)
            HapticManager.shared.operatorTrigger()
            SoundManager.shared.playSlashTrigger()

        case .gateTriggered(let gateType, let lane, let row, let result):
            switch result {
            case .jam:
                scene?.jamShuriken(lane: lane, row: row)
                HapticManager.shared.error()
                SoundManager.shared.playGateBlock()
                if simulation?.state.phase == .failed {
                    failReason = simulation?.state.failReason
                    nearMissOverflowMargin = simulation?.state.overflowMargin
                    nearMissBanked = simulation?.state.bankedCount
                    gamePhase = .failed
                    HapticManager.shared.failThud()
                    SoundManager.shared.playFailThud()
                    scene?.showFailFlash()
                }
            case .paint:
                // Find the paint gate's toColor from level data
                if let gate = simulation?.levelData.gates.first(where: {
                    $0.type == .paint && $0.lane == lane && $0.row == row
                }), let toColor = gate.toColor {
                    scene?.flashGatePaint(lane: lane, row: row, toColor: toColor)
                }
                SoundManager.shared.playPaintConvert()
            case .pass:
                // Update toggle gate visual indicator after each encounter
                if gateType == .toggle {
                    updateToggleGateIndicator(lane: lane, row: row)
                }
            }
            // Also update toggle indicator after jam
            if gateType == .toggle && result == .jam {
                updateToggleGateIndicator(lane: lane, row: row)
            }

        case .levelWon(let ops, _):
            starRating = StarCalculator.stars(
                operatorsUsed: ops,
                threeStarMax: levelData?.threeStarMaxOps ?? 6,
                twoStarMax: levelData?.twoStarMaxOps ?? 8
            )
            gamePhase = .won
            HapticManager.shared.winBurst()
            SoundManager.shared.playWinSting()
            scene?.showConfetti()

        case .tutorialPaused:
            gamePhase = .tutorialPaused
            if let text = simulation?.levelData.tutorialConfig?.overlayText {
                scene?.showTutorialOverlay(text: text)
            }

        case .operatorPlaced, .operatorRemoved:
            break
        }
    }
}
