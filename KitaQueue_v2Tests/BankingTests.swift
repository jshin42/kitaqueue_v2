import Testing
@testable import KitaQueue_v2

@Suite("Banking Tests")
struct BankingTests {

    private func makeAlignedLevel() -> LevelData {
        // All shuriken pre-aligned to correct banks
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

    private func makeMisbankLevel() -> LevelData {
        // First wave has red in lane 1 (green bank) — causes misbank
        var waves: [[LevelData.WaveEntry]] = []
        waves.append([
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),     // Red in green bank → misbank
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ])
        // Remaining waves are aligned
        let aligned: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        for _ in 1..<6 {
            waves.append(aligned)
        }
        return LevelData(
            id: 90,
            waves: waves,
            gates: [],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )
    }

    private func advanceToPlaying(_ sim: GameSimulation) {
        let dt = 1.0 / 60.0
        let steps = Int(GameConstants.totalPreviewDuration / dt) + 2
        for _ in 0..<steps {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
        }
    }

    // MARK: - Bank Success Tests

    @Test("Correct color banks successfully")
    func bankSuccess() {
        let sim = GameSimulation(levelData: makeAlignedLevel())
        let dt = 1.0 / 60.0

        // Run until at least one shuriken banks
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.bankedCount > 0 { break }
        }

        #expect(sim.state.bankedCount > 0, "At least one shuriken should have been banked")
    }

    @Test("All 24 shuriken bank on aligned level")
    func allShurikenBank() {
        let sim = GameSimulation(levelData: makeAlignedLevel())
        let dt = 1.0 / 60.0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .won { break }
        }

        #expect(sim.state.phase == .won)
        #expect(sim.state.bankedCount == 24)
    }

    @Test("Banking events are emitted")
    func bankingEvents() {
        let sim = GameSimulation(levelData: makeAlignedLevel())
        let dt = 1.0 / 60.0

        var bankEventCount = 0
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .shurikenBanked = event {
                    bankEventCount += 1
                }
            }
            if sim.state.phase == .won { break }
        }

        #expect(bankEventCount == 24, "Should emit 24 shurikenBanked events")
    }

    // MARK: - Misbank Tests

    @Test("Wrong color at bank causes misbank fail")
    func misbankFail() {
        let sim = GameSimulation(levelData: makeMisbankLevel())
        let dt = 1.0 / 60.0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .failed { break }
        }

        #expect(sim.state.phase == .failed)
        if case .misbank(let color, let lane) = sim.state.failReason {
            #expect(color == .red, "Misbanked shuriken should be red")
            #expect(lane == 1, "Misbank should be in lane 1 (green bank)")
        } else {
            Issue.record("Fail reason should be misbank, got: \(String(describing: sim.state.failReason))")
        }
    }

    @Test("Misbank emits shurikenMisbanked event")
    func misbankEvent() {
        let sim = GameSimulation(levelData: makeMisbankLevel())
        let dt = 1.0 / 60.0

        var misbankEventSeen = false
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .shurikenMisbanked = event {
                    misbankEventSeen = true
                }
            }
            if sim.state.phase == .failed { break }
        }

        #expect(misbankEventSeen, "Should emit shurikenMisbanked event")
    }

    @Test("Misbank is immediate fail — stops further processing")
    func misbankStopsProcessing() {
        let sim = GameSimulation(levelData: makeMisbankLevel())
        let dt = 1.0 / 60.0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .failed { break }
        }

        #expect(sim.state.phase == .failed)
        // bankedCount should be less than 24 since game failed early
        #expect(sim.state.bankedCount < 24)
    }

    // MARK: - Near-Miss: remainingToBank

    @Test("Near-miss remaining to bank calculation")
    func remainingToBank() {
        let sim = GameSimulation(levelData: makeMisbankLevel())
        let dt = 1.0 / 60.0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .failed { break }
        }

        let remaining = 24 - sim.state.bankedCount
        #expect(remaining > 0 && remaining <= 24, "Should have remaining shuriken to bank")
    }

    // MARK: - Bank Color Mapping

    @Test("Bank color mapping is correct")
    func bankColorMapping() {
        #expect(ShurikenColor.bankColor(for: 0) == .red)
        #expect(ShurikenColor.bankColor(for: 1) == .green)
        #expect(ShurikenColor.bankColor(for: 2) == .yellow)
        #expect(ShurikenColor.bankColor(for: 3) == .blue)
    }
}
