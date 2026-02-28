import Testing
@testable import KitaQueue_v2

@Suite("Operator Placement Tests")
struct OperatorTests {

    private func makeLevel2() -> LevelData {
        // Level with a color gate in lane 1 blocking red — requires 1 operator to reroute
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        // Put one red shuriken in lane 1 (will be blocked by green gate unless deflected)
        var waves = Array(repeating: wave, count: 6)
        // Override wave 0 entry 1: red shuriken in lane 1 instead of green
        waves[0] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .red),   // Needs deflecting to lane 0
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        return LevelData(
            id: 2,
            waves: waves,
            gates: [Gate(type: .color, lane: 1, row: 6, allowedColor: .green)],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )
    }

    private func makeSimpleLevel() -> LevelData {
        // No gates — all aligned. For testing pure operator mechanics.
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .red),
            .init(lane: 1, color: .green),
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        return LevelData(
            id: 99,
            waves: Array(repeating: wave, count: 6),
            gates: [],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )
    }

    /// Level where lanes 0 and 1 are swapped — deflecting via slot A corrects them.
    /// Green in lane 0 → deflect to lane 1 (green bank). Red in lane 1 → deflect to lane 0 (red bank).
    private func makeSwapLevel() -> LevelData {
        let wave: [LevelData.WaveEntry] = [
            .init(lane: 0, color: .green),   // Needs deflecting to lane 1
            .init(lane: 1, color: .red),     // Needs deflecting to lane 0
            .init(lane: 2, color: .yellow),
            .init(lane: 3, color: .blue)
        ]
        return LevelData(
            id: 98,
            waves: Array(repeating: wave, count: 6),
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
        }
    }

    // MARK: - Placement Tests

    @Test("Place operator succeeds")
    func placeOperator() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        let input = PlayerInput.place(row: 5, slot: .b, timestep: sim.state.timestep)
        let result = sim.applyInput(input)

        #expect(result == true)
        #expect(sim.state.operators.count == 1)
        #expect(sim.state.operators[0].row == 5)
        #expect(sim.state.operators[0].slot == .b)
        #expect(sim.state.operators[0].charges == GameConstants.chargesPerOperator)
        #expect(sim.state.totalOperatorsPlaced == 1)
    }

    @Test("Operator cap enforced at 3")
    func operatorCap() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        // Place 3 operators (cap)
        #expect(sim.applyInput(.place(row: 1, slot: .a, timestep: sim.state.timestep)))
        #expect(sim.applyInput(.place(row: 2, slot: .b, timestep: sim.state.timestep)))
        #expect(sim.applyInput(.place(row: 3, slot: .c, timestep: sim.state.timestep)))
        #expect(sim.state.operators.count == 3)

        // 4th placement should fail
        let result = sim.applyInput(.place(row: 4, slot: .a, timestep: sim.state.timestep))
        #expect(result == false)
        #expect(sim.state.operators.count == 3)
    }

    @Test("Cannot place duplicate at same position")
    func noDuplicatePlacement() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        #expect(sim.applyInput(.place(row: 5, slot: .b, timestep: sim.state.timestep)))
        let result = sim.applyInput(.place(row: 5, slot: .b, timestep: sim.state.timestep))
        #expect(result == false)
        #expect(sim.state.operators.count == 1)
    }

    @Test("Cannot place out of bounds")
    func outOfBoundsPlacement() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        #expect(!sim.applyInput(.place(row: 0, slot: .a, timestep: sim.state.timestep)))
        #expect(!sim.applyInput(.place(row: 13, slot: .a, timestep: sim.state.timestep)))
        #expect(sim.state.operators.isEmpty)
    }

    @Test("Cannot place during preview phase")
    func cannotPlaceDuringPreview() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        #expect(sim.state.phase == .preview)

        let result = sim.applyInput(.place(row: 5, slot: .b, timestep: sim.state.timestep))
        #expect(result == false)
        #expect(sim.state.operators.isEmpty)
    }

    // MARK: - Undo Tests

    @Test("Undo removes last placed operator")
    func undoLastOperator() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        #expect(sim.applyInput(.place(row: 1, slot: .a, timestep: sim.state.timestep)))
        #expect(sim.applyInput(.place(row: 3, slot: .b, timestep: sim.state.timestep)))
        #expect(sim.state.operators.count == 2)

        let undoResult = sim.applyInput(.undo(timestep: sim.state.timestep))
        #expect(undoResult == true)
        #expect(sim.state.operators.count == 1)
        #expect(sim.state.operators[0].row == 1) // First one remains
        #expect(sim.state.operators[0].slot == .a)
    }

    @Test("Undo on empty does nothing")
    func undoEmpty() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        let result = sim.applyInput(.undo(timestep: sim.state.timestep))
        #expect(result == false)
    }

    // MARK: - Deflection Tests

    @Test("Operator deflects shuriken between adjacent lanes")
    func deflection() {
        let sim = GameSimulation(levelData: makeSwapLevel())
        advanceToPlaying(sim)

        // Place operator at row 3, slot A (between lane 0 and lane 1)
        #expect(sim.applyInput(.place(row: 3, slot: .a, timestep: sim.state.timestep)))

        // Run until shuriken spawns and reaches row 3
        let dt = 1.0 / 60.0
        var deflected = false
        for _ in 0..<(60 * 10) {
            sim.tick(dt: dt)

            // Check if green shuriken was deflected from lane 0 to lane 1
            for s in sim.state.shuriken {
                if s.color == .green && s.lane == 1 {
                    deflected = true
                    break
                }
            }
            if deflected { break }
        }

        #expect(deflected, "Green shuriken should have been deflected from lane 0 to lane 1")
    }

    @Test("Charges decrement per trigger")
    func chargesDecrement() {
        let sim = GameSimulation(levelData: makeSwapLevel())
        advanceToPlaying(sim)

        // Place operator at row 6, slot A (between lane 0 and 1)
        #expect(sim.applyInput(.place(row: 6, slot: .a, timestep: sim.state.timestep)))

        // Run until at least one charge is consumed
        let dt = 1.0 / 60.0
        var triggered = false
        for _ in 0..<(60 * 10) {
            sim.tick(dt: dt)

            // Check if operator charges have decreased
            if let op = sim.state.operators.first(where: { $0.row == 6 && $0.slot == .a }) {
                if op.charges < GameConstants.chargesPerOperator {
                    triggered = true
                    break
                }
            }
            // Operator may have been removed if all charges consumed
            if sim.state.operators.isEmpty {
                triggered = true
                break
            }
        }

        #expect(triggered, "Operator should have been triggered and charges decremented")
    }

    @Test("Operator removed at 0 charges")
    func operatorExpiresAtZeroCharges() {
        // Use swap level: green in lane 0, red in lane 1.
        // Operator at slot A deflects both correctly: green→lane1, red→lane0.
        // Each wave triggers 2 charges (green + red). 3 charges consumed in 1.5 waves.
        let sim = GameSimulation(levelData: makeSwapLevel())
        advanceToPlaying(sim)

        #expect(sim.applyInput(.place(row: 4, slot: .a, timestep: sim.state.timestep)))

        let dt = 1.0 / 60.0
        var removed = false
        for _ in 0..<(60 * 25) {
            sim.tick(dt: dt)
            _ = sim.drainEvents()

            if sim.state.operators.isEmpty {
                removed = true
                break
            }
            if sim.state.phase == .won || sim.state.phase == .failed { break }
        }

        #expect(removed, "Operator should be removed after all charges consumed")
    }

    // MARK: - canPlace Tests

    @Test("canPlaceOperator returns correct results")
    func canPlaceCheck() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        #expect(sim.canPlaceOperator(row: 5, slot: .b))

        // Place one
        _ = sim.applyInput(.place(row: 5, slot: .b, timestep: sim.state.timestep))
        #expect(!sim.canPlaceOperator(row: 5, slot: .b)) // Duplicate position

        // Fill to cap
        _ = sim.applyInput(.place(row: 6, slot: .a, timestep: sim.state.timestep))
        _ = sim.applyInput(.place(row: 7, slot: .c, timestep: sim.state.timestep))
        #expect(!sim.canPlaceOperator(row: 8, slot: .a)) // Cap reached
    }

    // MARK: - totalOperatorsPlaced tracking

    @Test("totalOperatorsPlaced tracks cumulative count")
    func totalPlacedTracking() {
        let sim = GameSimulation(levelData: makeSimpleLevel())
        advanceToPlaying(sim)

        _ = sim.applyInput(.place(row: 1, slot: .a, timestep: sim.state.timestep))
        _ = sim.applyInput(.place(row: 2, slot: .b, timestep: sim.state.timestep))
        #expect(sim.state.totalOperatorsPlaced == 2)

        // Undo removes operator but totalPlaced doesn't decrease
        _ = sim.applyInput(.undo(timestep: sim.state.timestep))
        #expect(sim.state.totalOperatorsPlaced == 2)
        #expect(sim.state.operators.count == 1)
    }
}
