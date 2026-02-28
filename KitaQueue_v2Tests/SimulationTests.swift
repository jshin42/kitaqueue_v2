import Testing
@testable import KitaQueue_v2

@Suite("Simulation Core Tests")
struct SimulationTests {

    private func makeLevel1() -> LevelData {
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        return LevelData(
            id: 1,
            waves: Array(repeating: wave, count: 6),
            gates: [],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )
    }

    @Test("Level starts in preview phase")
    func previewPhase() {
        let sim = GameSimulation(levelData: makeLevel1())
        #expect(sim.state.phase == .preview)
    }

    @Test("Preview transitions to playing after 2s")
    func previewToPlaying() {
        let sim = GameSimulation(levelData: makeLevel1())
        let dt = 1.0 / 60.0
        let steps = Int(GameConstants.totalPreviewDuration / dt) + 2

        for _ in 0..<steps {
            sim.tick(dt: dt)
        }

        #expect(sim.state.phase == .playing)
    }

    @Test("Shuriken spawn after preview")
    func shurikenSpawn() {
        let sim = GameSimulation(levelData: makeLevel1())
        let dt = 1.0 / 60.0

        // Run through preview + some playing time
        for _ in 0..<300 { // ~5 seconds
            sim.tick(dt: dt)
        }

        #expect(sim.state.spawnedCount > 0)
        #expect(!sim.state.shuriken.isEmpty)
    }

    @Test("Level 1 auto-wins (all shuriken pre-aligned)")
    func level1AutoWin() {
        let sim = GameSimulation(levelData: makeLevel1())
        let dt = 1.0 / 60.0

        // Run for enough time to complete level
        // Preview (2s) + 6 waves * ~2.4s + travel time ~4s ≈ 20s
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            if sim.state.phase == .won { break }
        }

        #expect(sim.state.phase == .won)
        #expect(sim.state.bankedCount == 24)
    }

    @Test("Instant retry resets state")
    func instantRetry() {
        let sim = GameSimulation(levelData: makeLevel1())
        let dt = 1.0 / 60.0

        // Advance a bit
        for _ in 0..<300 {
            sim.tick(dt: dt)
        }

        #expect(sim.state.timestep > 0)

        sim.reset()

        #expect(sim.state.timestep == 0)
        #expect(sim.state.phase == .preview)
        #expect(sim.state.shuriken.isEmpty)
        #expect(sim.state.bankedCount == 0)
    }

    @Test("Star calculator")
    func starCalculator() {
        #expect(StarCalculator.stars(operatorsUsed: 4) == 3)
        #expect(StarCalculator.stars(operatorsUsed: 6) == 3)
        #expect(StarCalculator.stars(operatorsUsed: 7) == 2)
        #expect(StarCalculator.stars(operatorsUsed: 8) == 2)
        #expect(StarCalculator.stars(operatorsUsed: 9) == 1)
        #expect(StarCalculator.stars(operatorsUsed: 20) == 1)
    }

    @Test("Economy formulas")
    func economyFormulas() {
        #expect(StarCalculator.coins(stars: 0) == 10)
        #expect(StarCalculator.coins(stars: 1) == 15)
        #expect(StarCalculator.coins(stars: 2) == 20)
        #expect(StarCalculator.coins(stars: 3) == 25)

        #expect(StarCalculator.xp(stars: 0) == 100)
        #expect(StarCalculator.xp(stars: 1) == 150)
        #expect(StarCalculator.xp(stars: 2) == 200)
        #expect(StarCalculator.xp(stars: 3) == 250)
    }
}
