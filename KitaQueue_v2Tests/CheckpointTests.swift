import Testing
@testable import KitaQueue_v2

@Suite("Checkpoint + Fix It Tests")
struct CheckpointTests {

    // MARK: - CheckpointManager Basic Operations

    @Test("Save and restore checkpoint preserves state")
    func saveAndRestore() {
        let manager = CheckpointManager()
        var state = GameState()
        state.bankedCount = 10
        state.phase = .playing
        state.jamCounts[1] = 2

        manager.saveCheckpoint(state)

        let restored = manager.restoreCheckpoint()
        #expect(restored != nil)
        #expect(restored?.bankedCount == 10)
        #expect(restored?.jamCounts[1] == 2)
    }

    @Test("Clear removes checkpoint")
    func clearCheckpoint() {
        let manager = CheckpointManager()
        var state = GameState()
        state.bankedCount = 5
        manager.saveCheckpoint(state)
        manager.clear()

        #expect(manager.restoreCheckpoint() == nil)
    }

    @Test("Latest checkpoint overwrites previous")
    func latestOverwrites() {
        let manager = CheckpointManager()

        var state1 = GameState()
        state1.bankedCount = 5
        manager.saveCheckpoint(state1)

        var state2 = GameState()
        state2.bankedCount = 15
        manager.saveCheckpoint(state2)

        let restored = manager.restoreCheckpoint()
        #expect(restored?.bankedCount == 15)
    }

    // MARK: - Overflow Fix

    @Test("Overflow fix removes 1 jammed shuriken in failing lane")
    func overflowFixRemovesJam() {
        var state = GameState()
        state.phase = .failed
        state.failReason = .overflow(lane: 1)
        state.jamCounts[1] = 3

        // Add 3 jammed shuriken in lane 1
        state.shuriken.append(Shuriken(id: 0, color: .red, lane: 1, progressY: 0.5, isJammed: true))
        state.shuriken.append(Shuriken(id: 1, color: .red, lane: 1, progressY: 0.4, isJammed: true))
        state.shuriken.append(Shuriken(id: 2, color: .red, lane: 1, progressY: 0.3, isJammed: true))
        // Add a normal shuriken in lane 0
        state.shuriken.append(Shuriken(id: 3, color: .green, lane: 0, progressY: 0.2))

        CheckpointManager.applyOverflowFix(&state, lane: 1)

        #expect(state.phase == .playing, "Phase should be restored to playing")
        #expect(state.failReason == nil, "Fail reason should be cleared")
        #expect(state.jamCounts[1] == 2, "Jam count should decrease by 1")

        let jammedInLane1 = state.shuriken.filter { $0.isJammed && $0.lane == 1 }
        #expect(jammedInLane1.count == 2, "Should have 2 jammed shuriken remaining in lane 1")

        let normalShuriken = state.shuriken.filter { !$0.isJammed }
        #expect(normalShuriken.count == 1, "Normal shuriken should be unaffected")
    }

    @Test("Overflow fix with no jammed shuriken does not crash")
    func overflowFixNoJams() {
        var state = GameState()
        state.phase = .failed
        state.failReason = .overflow(lane: 2)

        CheckpointManager.applyOverflowFix(&state, lane: 2)

        #expect(state.phase == .playing)
        #expect(state.failReason == nil)
    }

    // MARK: - Misbank Fix

    @Test("Misbank fix removes last placed operator")
    func misbankFixRemovesOperator() {
        var state = GameState()
        state.phase = .failed
        state.failReason = .misbank(shurikenColor: .red, bankLane: 1)

        state.operators.append(Operator(id: 0, row: 4, slot: .a, charges: 2, placementOrder: 0, placementTimestep: 0))
        state.operators.append(Operator(id: 1, row: 6, slot: .b, charges: 3, placementOrder: 1, placementTimestep: 100))

        CheckpointManager.applyMisbankFix(&state)

        #expect(state.phase == .playing, "Phase should be restored to playing")
        #expect(state.failReason == nil, "Fail reason should be cleared")
        #expect(state.operators.count == 1, "Should have 1 operator remaining")
        #expect(state.operators.first?.id == 0, "First operator should remain")
    }

    @Test("Misbank fix with no operators does not crash")
    func misbankFixNoOperators() {
        var state = GameState()
        state.phase = .failed
        state.failReason = .misbank(shurikenColor: .green, bankLane: 0)

        CheckpointManager.applyMisbankFix(&state)

        #expect(state.phase == .playing)
        #expect(state.failReason == nil)
    }

    // MARK: - Fix It Integration with Simulation

    @Test("Fix It overflow restore produces valid resumable state")
    func fixItOverflowIntegration() {
        // Run Level 5 to overflow failure
        let level = LevelLoader.loadOrGenerate(id: 5)
        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        // Advance past preview
        let previewSteps = Int(GameConstants.totalPreviewDuration / dt) + 5
        for _ in 0..<previewSteps {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
        }
        if sim.state.phase == .tutorialPaused {
            sim.resumeFromTutorial()
        }

        // Run until fail
        for _ in 0..<(60 * 30) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .failed { break }
        }

        #expect(sim.state.phase == .failed, "Level 5 should fail without operators")

        // Apply Fix It
        guard let checkpoint = sim.checkpointManager.restoreCheckpoint() else {
            #expect(Bool(false), "Checkpoint should exist")
            return
        }
        var restored = checkpoint

        if case .overflow(let lane) = sim.state.failReason {
            CheckpointManager.applyOverflowFix(&restored, lane: lane)
            sim.restoreState(restored)

            #expect(sim.state.phase == .playing, "Should be playing after fix")
            #expect(sim.state.failReason == nil, "Fail reason should be nil after fix")

            // Continue running - should be able to process more ticks without crash
            for _ in 0..<60 {
                sim.tick(dt: dt)
                _ = sim.drainEvents()
            }
            #expect(sim.state.phase == .playing || sim.state.phase == .won || sim.state.phase == .failed,
                    "Simulation should be in a valid phase after Fix It resume")
        }
    }

    // MARK: - Star Calculator

    @Test("Star calculator returns correct ratings")
    func starCalculatorRatings() {
        #expect(StarCalculator.stars(operatorsUsed: 5) == 3)
        #expect(StarCalculator.stars(operatorsUsed: 6) == 3)
        #expect(StarCalculator.stars(operatorsUsed: 7) == 2)
        #expect(StarCalculator.stars(operatorsUsed: 8) == 2)
        #expect(StarCalculator.stars(operatorsUsed: 9) == 1)
        #expect(StarCalculator.stars(operatorsUsed: 20) == 1)
        #expect(StarCalculator.stars(operatorsUsed: 0) == 3)
    }

    @Test("Star calculator coins and XP formulas")
    func starCalculatorEconomy() {
        // 3 stars: 10 + 5*3 = 25 coins, 100 + 50*3 = 250 XP
        #expect(StarCalculator.coins(stars: 3) == 25)
        #expect(StarCalculator.xp(stars: 3) == 250)

        // 2 stars: 10 + 5*2 = 20 coins, 100 + 50*2 = 200 XP
        #expect(StarCalculator.coins(stars: 2) == 20)
        #expect(StarCalculator.xp(stars: 2) == 200)

        // 1 star: 10 + 5*1 = 15 coins, 100 + 50*1 = 150 XP
        #expect(StarCalculator.coins(stars: 1) == 15)
        #expect(StarCalculator.xp(stars: 1) == 150)
    }

    @Test("Missed 3-star calculation")
    func missedThreeStar() {
        #expect(StarCalculator.missedThreeStarBy(operatorsUsed: 7, threeStarMax: 6) == 1)
        #expect(StarCalculator.missedThreeStarBy(operatorsUsed: 10, threeStarMax: 6) == 4)
        #expect(StarCalculator.missedThreeStarBy(operatorsUsed: 6, threeStarMax: 6) == nil)
        #expect(StarCalculator.missedThreeStarBy(operatorsUsed: 3, threeStarMax: 6) == nil)
    }
}
