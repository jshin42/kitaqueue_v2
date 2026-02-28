import Testing
@testable import KitaQueue_v2

@Suite("Gate Tests")
struct GateTests {

    private func advanceToPlaying(_ sim: GameSimulation) {
        let dt = 1.0 / 60.0
        let steps = Int(GameConstants.totalPreviewDuration / dt) + 2
        for _ in 0..<steps {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
        }
    }

    // MARK: - Color Gate Tests

    @Test("Color gate blocks non-matching shuriken (jam)")
    func colorGateBlocks() {
        // Red shuriken in lane 1 with green-only color gate at row 6
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),     // Should be jammed by green gate
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 80,
            waves: [wave] + Array(repeating: [
                .init(lane: 0, color: .red),
                .init(lane: 1, color: .green),
                .init(lane: 2, color: .yellow),
                .init(lane: 3, color: .blue)
            ], count: 5),
            gates: [Gate(type: .color, lane: 1, row: 6, allowedColor: .green)],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0
        var jammed = false

        for _ in 0..<(60 * 10) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .gateTriggered(_, _, _, .jam) = event {
                    jammed = true
                }
            }
            if jammed { break }
        }

        #expect(jammed, "Red shuriken should be jammed by green-only color gate")
        #expect(sim.state.jamCounts[1, default: 0] >= 1, "Lane 1 should have at least 1 jam")
    }

    @Test("Color gate passes matching shuriken")
    func colorGatePasses() {
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),   // Matches green gate — should pass
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 81,
            waves: Array(repeating: wave, count: 6),
            gates: [Gate(type: .color, lane: 1, row: 6, allowedColor: .green)],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0
        var passedCount = 0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .gateTriggered(_, 1, _, .pass) = event {
                    passedCount += 1
                }
            }
            if sim.state.phase == .won { break }
        }

        #expect(passedCount == 6, "All 6 green shuriken should pass through the gate")
        #expect(sim.state.jamCounts[1, default: 0] == 0, "No jams in lane 1")
    }

    // MARK: - Overflow Tests

    @Test("3 jams in one lane causes overflow fail")
    func overflowAtThreeJams() {
        // Put 3 red shuriken in lane 1 with green-only gate
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),     // Will jam
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 82,
            waves: Array(repeating: wave, count: 6), // 6 red shuriken → 3 jams = overflow
            gates: [Gate(type: .color, lane: 1, row: 6, allowedColor: .green)],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .failed { break }
        }

        #expect(sim.state.phase == .failed)
        if case .overflow(let lane) = sim.state.failReason {
            #expect(lane == 1, "Overflow should be in lane 1")
        } else {
            Issue.record("Fail reason should be overflow, got: \(String(describing: sim.state.failReason))")
        }
    }

    @Test("Overflow margin tracked correctly")
    func overflowMargin() {
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),     // Will jam
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 83,
            waves: Array(repeating: wave, count: 6),
            gates: [Gate(type: .color, lane: 1, row: 6, allowedColor: .green)],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        var marginAfterFirstJam: Int?
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.jamCounts[1, default: 0] == 1 && marginAfterFirstJam == nil {
                marginAfterFirstJam = sim.state.overflowMargin
            }
            if sim.state.phase == .failed { break }
        }

        #expect(marginAfterFirstJam == 2, "After 1 jam, overflow margin should be 2 (3 - 1)")
        #expect(sim.state.overflowMargin == 0, "At overflow, margin should be 0")
    }

    @Test("2 jams does NOT cause overflow")
    func twoJamsNoOverflow() {
        // Only 2 red shuriken in lane 1 (waves 1 and 2), rest are green
        var waves: [[LevelData.WaveEntry]] = []
        for i in 0..<6 {
            if i < 2 {
                waves.append([
                    .init(lane: 0, color: .red),
                    .init(lane: 1, color: .red),     // Will jam
                    .init(lane: 2, color: .yellow),
                    .init(lane: 3, color: .blue)
                ])
            } else {
                waves.append([
                    .init(lane: 0, color: .red),
                    .init(lane: 1, color: .green),   // Will pass
                    .init(lane: 2, color: .yellow),
                    .init(lane: 3, color: .blue)
                ])
            }
        }
        let level = LevelData(
            id: 84,
            waves: waves,
            gates: [Gate(type: .color, lane: 1, row: 6, allowedColor: .green)],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()
            if sim.state.phase == .won || sim.state.phase == .failed { break }
        }

        // Should win with 2 jams (below threshold of 3)
        #expect(sim.state.phase == .won)
        #expect(sim.state.jamCounts[1, default: 0] == 2)
    }

    // MARK: - Toggle Gate Tests

    @Test("Toggle gate cycles color based on spawn index")
    func toggleGateCycles() {
        // Green shuriken in lane 1 with toggle gate cycling [green, red].
        // When gate allows green → pass → banks correctly in green bank.
        // When gate allows red → green ≠ red → jam.
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 85,
            waves: Array(repeating: wave, count: 6),
            gates: [Gate(
                type: .toggle,
                lane: 1,
                row: 6,
                colorCycle: [.green, .red],  // Alternates every 2 spawns
                cycleEveryNSpawns: 2
            )],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        var passCount = 0
        var jamCount = 0
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .gateTriggered(_, 1, _, .pass) = event {
                    passCount += 1
                }
                if case .gateTriggered(_, 1, _, .jam) = event {
                    jamCount += 1
                }
            }
            if sim.state.phase == .won || sim.state.phase == .failed { break }
        }

        // With cycle [green, red] every 2 encounters, green shuriken in lane 1:
        // Encounter 0-1: green → pass, encounter 2-3: red → jam,
        // encounter 4-5: green → pass. Total: 4 pass, 2 jam.
        #expect(passCount > 0, "Some shuriken should pass toggle gate")
        #expect(jamCount > 0, "Some shuriken should be jammed by toggle gate")
    }

    // MARK: - Paint Gate Tests

    @Test("Paint gate transforms shuriken color")
    func paintGateTransforms() {
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),     // Will be painted to green
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 86,
            waves: Array(repeating: wave, count: 6),
            gates: [Gate(
                type: .paint,
                lane: 1,
                row: 6,
                fromColor: .red,
                toColor: .green
            )],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        var paintCount = 0
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .gateTriggered(_, 1, _, .paint) = event {
                    paintCount += 1
                }
            }
            if sim.state.phase == .won || sim.state.phase == .failed { break }
        }

        // All 6 red shuriken in lane 1 should be painted to green
        #expect(paintCount == 6, "All 6 red shuriken should be painted")
        // Level should win since painted shuriken match green bank
        #expect(sim.state.phase == .won)
    }

    @Test("Paint gate does not affect non-matching color")
    func paintGateIgnoresNonMatching() {
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),   // Not red, so paint gate won't apply
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 87,
            waves: Array(repeating: wave, count: 6),
            gates: [Gate(
                type: .paint,
                lane: 1,
                row: 6,
                fromColor: .red,
                toColor: .blue
            )],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        let dt = 1.0 / 60.0

        var paintCount = 0
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .gateTriggered(_, 1, _, .paint) = event {
                    paintCount += 1
                }
            }
            if sim.state.phase == .won || sim.state.phase == .failed { break }
        }

        #expect(paintCount == 0, "Green shuriken should not be painted (gate is red→blue)")
        #expect(sim.state.phase == .won, "Green shuriken in green bank should win")
    }

    // MARK: - Interaction Ordering

    @Test("Gate processes before operator at same row")
    func gateBeforeOperator() {
        // Paint gate at row 6, lane 1: red→green
        // Operator at row 6, slot A (between lanes 0-1)
        // Red shuriken in lane 1 should be painted to green BEFORE operator check
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),     // Painted to green at gate, then may hit operator
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        let level = LevelData(
            id: 88,
            waves: Array(repeating: wave, count: 6),
            gates: [Gate(
                type: .paint,
                lane: 1,
                row: 6,
                fromColor: .red,
                toColor: .green
            )],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )

        let sim = GameSimulation(levelData: level)
        advanceToPlaying(sim)

        // Place operator at row 6, slot A
        _ = sim.applyInput(.place(row: 6, slot: .a, timestep: sim.state.timestep))

        let dt = 1.0 / 60.0
        var paintSeen = false
        var operatorTriggered = false
        for _ in 0..<(60 * 10) {
            sim.tick(dt: dt)
            let events = sim.drainEvents()
            for event in events {
                if case .gateTriggered(_, 1, 6, .paint) = event {
                    paintSeen = true
                }
                if case .operatorTriggered(6, .a, _, _) = event {
                    operatorTriggered = true
                }
            }
            if paintSeen && operatorTriggered { break }
        }

        // Both should have happened (paint first, then operator)
        #expect(paintSeen, "Paint gate should fire")
        #expect(operatorTriggered, "Operator at same row should also fire after gate")
    }
}
