import Testing
@testable import KitaQueue_v2

@Suite("Level Solver Tests")
struct LevelSolverTests {

    // MARK: - Simulation Helpers

    /// Fixed timestep matching the simulation engine
    private let dt = 1.0 / 60.0

    /// Maximum ticks to run a simulation (~30 seconds of game time)
    private let maxTicks = 60 * 30

    /// Advance a simulation past the preview phase into playing.
    /// Handles tutorialPaused levels by resuming them.
    private func advancePastPreview(_ sim: GameSimulation) {
        let previewSteps = Int(GameConstants.totalPreviewDuration / dt) + 5
        for _ in 0..<previewSteps {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
        }
        // If the level pauses for tutorial, resume
        if sim.state.phase == .tutorialPaused {
            sim.resumeFromTutorial()
        }
    }

    /// Run the simulation to completion (won, failed, or timeout).
    /// Returns the final phase.
    @discardableResult
    private func runToCompletion(_ sim: GameSimulation) -> GameState.GamePhase {
        for _ in 0..<maxTicks {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            // Handle tutorial pauses that occur mid-level
            if sim.state.phase == .tutorialPaused {
                sim.resumeFromTutorial()
            }
            if sim.state.phase == .won || sim.state.phase == .failed {
                return sim.state.phase
            }
        }
        return sim.state.phase
    }

    /// Place operators and then run to completion.
    /// Operators are placed immediately after preview ends (before shuriken reach the rows).
    private func solveWithPlacements(
        levelData: LevelData,
        placements: [(row: Int, slot: BoundarySlot)]
    ) -> (phase: GameState.GamePhase, operatorsUsed: Int, bankedCount: Int) {
        let sim = GameSimulation(levelData: levelData)
        advancePastPreview(sim)

        // Place all operators
        for placement in placements {
            let success = sim.applyInput(.place(
                row: placement.row,
                slot: placement.slot,
                timestep: sim.state.timestep
            ))
            _ = sim.drainEvents()
            if !success {
                break
            }
        }

        let finalPhase = runToCompletion(sim)
        return (finalPhase, sim.state.totalOperatorsPlaced, sim.state.bankedCount)
    }

    // MARK: - FTUE Levels (1-5): Known Solutions

    @Test("Level 1: auto-win with 0 operators (FTUE: Banking)")
    func level1AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 1)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 1 should auto-win with no operators")
        #expect(result.bankedCount == 24, "Level 1 should bank all 24 shuriken")
        #expect(result.operatorsUsed == 0, "Level 1 should require 0 operators")
    }

    @Test("Level 2: winnable with 1 operator (FTUE: Place one slash)")
    func level2Winnable() {
        let level = LevelLoader.loadOrGenerate(id: 2)
        let result = solveWithPlacements(
            levelData: level,
            placements: [(row: 4, slot: .a)]
        )

        #expect(result.phase == .won, "Level 2 should be winnable with 1 operator at row 4 slot A")
        #expect(result.operatorsUsed <= level.threeStarMaxOps, "Level 2 solution should achieve 3 stars")
    }

    @Test("Level 3: winnable with 2 operators (FTUE: Charges)")
    func level3Winnable() {
        let level = LevelLoader.loadOrGenerate(id: 3)
        let result = solveWithPlacements(
            levelData: level,
            placements: [(row: 5, slot: .a), (row: 3, slot: .a)]
        )

        #expect(result.phase == .won, "Level 3 should be winnable with 2 operators")
        #expect(result.operatorsUsed <= level.threeStarMaxOps, "Level 3 solution should achieve 3 stars")
    }

    @Test("Level 4: auto-win with paint gate (FTUE: Paint Gate)")
    func level4AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 4)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 4 should auto-win with paint gate converting red -> green")
        #expect(result.bankedCount == 24, "Level 4 should bank all 24 shuriken")
        #expect(result.operatorsUsed == 0, "Level 4 should require 0 operators")
    }

    // Level 5 is designed to teach overflow (3 reds jam in lane 1).
    // Solving it requires TIMED operator placement (place after lane 0 shuriken pass
    // the row, then deflect lane 1 reds). Pre-placed operators deflect non-selectively,
    // so no static placement works. Overflow fail verified in edge cases below.

    // MARK: - Levels 6-10: Auto-Win Verification
    // Levels 6-10 are designed with max 2 jams per gated lane (under threshold of 3).
    // They auto-win with 0 operators. Some shuriken jam but not enough for overflow.

    @Test("Level 6: auto-win with 0 operators (2 color gates, max 2 jams per lane)")
    func level6AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 6)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 6 should auto-win (max 2 jams per gated lane)")
        #expect(result.operatorsUsed == 0, "Level 6 should require 0 operators for auto-win")
    }

    @Test("Level 7: auto-win with 0 operators (toggle gate + color gate, max 2 jams per lane)")
    func level7AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 7)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 7 should auto-win (toggle gate jams 2, color gate jams 2)")
        #expect(result.operatorsUsed == 0, "Level 7 should require 0 operators for auto-win")
    }

    @Test("Level 8: auto-win with 0 operators (paint + 2 color gates, max 2 jams per lane)")
    func level8AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 8)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 8 should auto-win (paint converts reds, max 2 jams)")
        #expect(result.operatorsUsed == 0, "Level 8 should require 0 operators for auto-win")
    }

    @Test("Level 9: auto-win with 0 operators (color gates + paint gate, max 2 jams in lane 0)")
    func level9AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 9)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 9 should auto-win (2 greens jam in lane 0, paint handles lane 2)")
        #expect(result.operatorsUsed == 0, "Level 9 should require 0 operators for auto-win")
    }

    @Test("Level 10: auto-win with 0 operators (color gates + paint gate, max 2 jams per lane)")
    func level10AutoWin() {
        let level = LevelLoader.loadOrGenerate(id: 10)
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(result.phase == .won, "Level 10 should auto-win (paint converts lane 1, max 2 jams)")
        #expect(result.operatorsUsed == 0, "Level 10 should require 0 operators for auto-win")
    }

    // MARK: - Determinism Verification

    @Test("Same solution produces identical results on replay (determinism)")
    func determinismCheck() {
        let level = LevelLoader.loadOrGenerate(id: 5)
        let placements: [(row: Int, slot: BoundarySlot)] = [(row: 4, slot: .a)]

        // Run twice with identical inputs
        let result1 = solveWithPlacements(levelData: level, placements: placements)
        let result2 = solveWithPlacements(levelData: level, placements: placements)

        #expect(result1.phase == result2.phase, "Phase should be identical across runs")
        #expect(result1.bankedCount == result2.bankedCount, "Banked count should be identical across runs")
        #expect(result1.operatorsUsed == result2.operatorsUsed, "Operators used should be identical across runs")
    }

    @Test("All 10 levels produce deterministic results (100 runs each)")
    func allLevelsDeterministic() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            let firstResult = solveWithPlacements(levelData: level, placements: [])

            for _ in 0..<99 {
                let result = solveWithPlacements(levelData: level, placements: [])
                #expect(result.phase == firstResult.phase,
                        "Level \(id): phase should be identical across runs")
                #expect(result.bankedCount == firstResult.bankedCount,
                        "Level \(id): banked count should be identical across runs")
            }
        }
    }

    // MARK: - Edge Cases

    @Test("Level without operators fails if gates block 3+ shuriken")
    func noOperatorsCausesFail() {
        let level = LevelLoader.loadOrGenerate(id: 5)
        // Level 5 without any operators: 3 reds jam in lane 1 -> overflow
        let result = solveWithPlacements(levelData: level, placements: [])

        #expect(
            result.phase == .failed,
            "Level 5 without operators should fail (overflow from 3 jammed reds)"
        )
    }

    @Test("Wrong operator placement still fails")
    func wrongPlacementFails() {
        let level = LevelLoader.loadOrGenerate(id: 2)
        // Place operator at slot C (between lanes 2-3) which doesn't help the red in lane 1
        let result = solveWithPlacements(
            levelData: level,
            placements: [(row: 4, slot: .c)]
        )

        // The red shuriken in lane 1 is not deflected, so it jams at the color gate
        // This doesn't necessarily cause a fail (only 1 jam, threshold is 3),
        // but it won't achieve a full win either
        #expect(
            result.bankedCount < 24,
            "Wrong operator placement should not bank all shuriken"
        )
    }

    @Test("Level 5 overflow shows correct fail reason")
    func level5OverflowFailReason() {
        let level = LevelLoader.loadOrGenerate(id: 5)
        let sim = GameSimulation(levelData: level)
        advancePastPreview(sim)
        runToCompletion(sim)

        #expect(sim.state.phase == .failed)
        if case .overflow(let lane) = sim.state.failReason {
            #expect(lane == 1, "Overflow should occur in lane 1 (where reds jam)")
        } else {
            #expect(Bool(false), "Fail reason should be overflow, got: \(String(describing: sim.state.failReason))")
        }
    }
}
