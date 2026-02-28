import Foundation

/// Pure deterministic game simulation. No UIKit/SpriteKit imports.
/// Fixed 60Hz timestep accumulator. Row-based interactions.
final class GameSimulation {
    private(set) var state: GameState
    let levelData: LevelData

    private let spawnManager: SpawnManager
    private var interactionProcessor = InteractionProcessor()
    private let bankValidator = BankValidator()
    private let operatorManager = OperatorManager()
    let checkpointManager = CheckpointManager()

    private var accumulator: Double = 0
    private static let fixedDt: Double = 1.0 / 60.0

    weak var delegate: SimulationDelegate?

    init(levelData: LevelData) {
        self.levelData = levelData
        self.state = GameState()
        self.spawnManager = SpawnManager(levelData: levelData)
    }

    // MARK: - Tick

    /// Call from render loop with variable dt. Internally uses fixed timestep.
    func tick(dt: Double) {
        guard state.phase == .preview || state.phase == .playing else { return }

        accumulator += dt

        while accumulator >= Self.fixedDt {
            accumulator -= Self.fixedDt
            fixedUpdate(Self.fixedDt)
            state.timestep += 1

            // Stop processing if game ended
            if state.phase != .preview && state.phase != .playing { break }
        }
    }

    private func fixedUpdate(_ dt: Double) {
        state.elapsedTime += dt

        // Preview phase
        if state.phase == .preview {
            state.previewElapsed += dt
            if state.previewElapsed >= GameConstants.totalPreviewDuration {
                state.phase = .playing

                // If tutorial level, pause for tutorial overlay
                if levelData.tutorialConfig?.pauseBeforeFirstSpawn == true {
                    state.phase = .tutorialPaused
                    delegate?.simulationDidEmitEvent(.tutorialPaused)
                    return
                }
            }
            return
        }

        // Move shuriken
        moveShurikenAndProcess(dt: dt)

        // Spawn
        spawnIfNeeded(dt: dt)

        // Check win condition
        checkWinCondition()
    }

    // MARK: - Movement + Interactions

    private func moveShurikenAndProcess(dt: Double) {
        let progressPerTick = dt / (GameConstants.shurikenRowTravelTime * Double(GameConstants.rowCount))

        // Move all active shuriken
        for i in state.shuriken.indices {
            guard !state.shuriken[i].isJammed else { continue }
            state.shuriken[i].progressY += progressPerTick
        }

        // Process row boundary interactions (gate -> operator -> update)
        let interactionEvents = interactionProcessor.processInteractions(
            state: &state,
            gates: levelData.gates,
            dt: dt
        )
        for event in interactionEvents {
            delegate?.simulationDidEmitEvent(event)

            // Save checkpoint at interaction points
            checkpointManager.saveCheckpoint(state)
        }

        guard state.phase == .playing else { return }

        // Bank validation
        let bankEvents = bankValidator.validateBanking(state: &state)
        for event in bankEvents {
            delegate?.simulationDidEmitEvent(event)
        }
    }

    // MARK: - Spawning

    private func spawnIfNeeded(dt: Double) {
        state.timeSinceLastSpawn += dt

        // Handle breath window
        if state.waveBreathing {
            state.breathElapsed += dt
            if state.breathElapsed >= GameConstants.breathWindowDuration {
                state.waveBreathing = false
                state.breathElapsed = 0
            } else {
                return
            }
        }

        if let spawn = spawnManager.shouldSpawn(state: state, dt: dt) {
            let shuriken = Shuriken(
                id: state.spawnedCount,
                color: spawn.color,
                lane: spawn.lane,
                progressY: 0
            )
            state.shuriken.append(shuriken)
            state.spawnedCount += 1
            state.globalSpawnIndex += 1
            state.shurikenInCurrentWave += 1
            state.timeSinceLastSpawn = 0

            delegate?.simulationDidEmitEvent(.shurikenSpawned(id: shuriken.id, color: spawn.color, lane: spawn.lane))

            // Check if wave is complete
            if state.shurikenInCurrentWave >= GameConstants.shurikenPerWave {
                state.currentWave += 1
                state.shurikenInCurrentWave = 0
                if state.currentWave < levelData.waves.count {
                    state.waveBreathing = true
                    state.breathElapsed = 0
                }
            }
        }
    }

    // MARK: - Win Condition

    private func checkWinCondition() {
        // Win = all waves processed + all shuriken resolved (banked or jammed) + no fail
        guard state.phase == .playing else { return }
        guard state.spawnedCount >= levelData.totalShuriken else { return }

        // All shuriken must be resolved (banked or jammed - none still moving)
        let activeShuriken = state.shuriken.filter { !$0.isJammed }
        guard activeShuriken.isEmpty else { return }

        // WIN
        state.phase = .won
        delegate?.simulationDidEmitEvent(.levelWon(
            operatorsUsed: state.totalOperatorsPlaced,
            bankedCount: state.bankedCount
        ))
    }

    // MARK: - Input

    func applyInput(_ input: PlayerInput) -> Bool {
        guard state.phase == .playing else { return false }

        switch input {
        case .place(let row, let slot, _):
            let success = operatorManager.placeOperator(row: row, slot: slot, state: &state)
            if success {
                delegate?.simulationDidEmitEvent(.operatorPlaced(
                    row: row,
                    slot: slot,
                    activeCount: state.operators.count
                ))
            }
            return success

        case .undo:
            if let removed = operatorManager.undoLastOperator(state: &state) {
                delegate?.simulationDidEmitEvent(.operatorRemoved(row: removed.row, slot: removed.slot))
                return true
            }
            return false
        }
    }

    /// Resume from tutorial pause
    func resumeFromTutorial() {
        guard state.phase == .tutorialPaused else { return }
        state.phase = .playing
    }

    /// Check if operator can be placed (for ghost preview)
    func canPlaceOperator(row: Int, slot: BoundarySlot) -> Bool {
        operatorManager.canPlace(row: row, slot: slot, state: state)
    }

    /// Get spawn preview colors
    func spawnPreview(count: Int) -> [ShurikenColor] {
        spawnManager.spawnPreview(state: state, count: count)
    }

    /// Reset for instant retry (sub-100ms, same level)
    func reset() {
        state = GameState()
        accumulator = 0
        checkpointManager.clear()
    }
}

// MARK: - Simulation Events

enum SimulationEvent: Sendable {
    case shurikenSpawned(id: Int, color: ShurikenColor, lane: Int)
    case shurikenBanked(shurikenId: Int, bankColor: ShurikenColor)
    case shurikenMisbanked(shurikenId: Int, color: ShurikenColor, bankLane: Int)
    case operatorPlaced(row: Int, slot: BoundarySlot, activeCount: Int)
    case operatorTriggered(row: Int, slot: BoundarySlot, shurikenId: Int, remainingCharges: Int)
    case operatorRemoved(row: Int, slot: BoundarySlot)
    case gateTriggered(type: GateType, lane: Int, row: Int, result: GateResult)
    case levelWon(operatorsUsed: Int, bankedCount: Int)
    case tutorialPaused

    enum GateResult: Sendable {
        case pass, jam, paint
    }
}

// MARK: - Delegate

protocol SimulationDelegate: AnyObject {
    func simulationDidEmitEvent(_ event: SimulationEvent)
}
