import Testing
@testable import KitaQueue_v2

@Suite("Determinism Tests")
struct DeterminismTests {

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

    @Test("Same inputs produce same hash x100")
    func determinismHashCompare() {
        let level = makeLevel1()
        var hashes: Set<String> = []

        for _ in 0..<100 {
            let sim = GameSimulation(levelData: level)
            let dt = 1.0 / 60.0

            for _ in 0..<(60 * 25) {
                sim.tick(dt: dt)
                if sim.state.phase == .won || sim.state.phase == .failed { break }
            }

            let hash = GameStateHasher.hash(sim.state)
            hashes.insert(hash)
        }

        #expect(hashes.count == 1, "Determinism violated: got \(hashes.count) unique hashes")
    }
}
