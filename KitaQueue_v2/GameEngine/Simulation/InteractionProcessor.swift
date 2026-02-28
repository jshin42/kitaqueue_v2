import Foundation

/// Processes interactions at row boundaries.
/// Enforces ordering: gate effect -> operator effect -> state update.
/// One deflection per row per shuriken.
struct InteractionProcessor: Sendable {

    /// Process all shuriken that have crossed a row boundary this tick.
    /// Returns events that occurred.
    mutating func processInteractions(
        state: inout GameState,
        gates: [Gate],
        dt: Double
    ) -> [SimulationEvent] {
        var events: [SimulationEvent] = []

        for i in state.shuriken.indices {
            guard !state.shuriken[i].isJammed else { continue }

            let shuriken = state.shuriken[i]
            let previousRow = rowForProgress(shuriken.progressY - progressPerTick(dt))
            let currentRow = rowForProgress(shuriken.progressY)

            // Check if we crossed into a new row
            guard currentRow > previousRow else { continue }
            let rowEntered = currentRow

            guard rowEntered >= 1 && rowEntered <= GameConstants.rowCount else { continue }

            let entryLane = state.shuriken[i].lane

            // 1) Gate effect (if gate at this row + lane)
            if let gate = gates.first(where: { $0.row == rowEntered && $0.lane == entryLane }) {
                let gateEvents = applyGateEffect(
                    gate: gate,
                    shurikenIndex: i,
                    state: &state
                )
                events.append(contentsOf: gateEvents)

                // If jammed, skip operator check
                if state.shuriken[i].isJammed { continue }
            }

            // 2) Operator effect (check boundary slot adjacent to ENTRY lane)
            let operatorEvents = applyOperatorEffect(
                shurikenIndex: i,
                entryLane: entryLane,
                row: rowEntered,
                state: &state
            )
            events.append(contentsOf: operatorEvents)
        }

        return events
    }

    // MARK: - Gate Effects

    private func applyGateEffect(
        gate: Gate,
        shurikenIndex: Int,
        state: inout GameState
    ) -> [SimulationEvent] {
        switch gate.type {
        case .color:
            return applyColorGate(gate: gate, shurikenIndex: shurikenIndex, state: &state)
        case .toggle:
            return applyToggleGate(gate: gate, shurikenIndex: shurikenIndex, state: &state)
        case .paint:
            return applyPaintGate(gate: gate, shurikenIndex: shurikenIndex, state: &state)
        }
    }

    private func applyColorGate(gate: Gate, shurikenIndex: Int, state: inout GameState) -> [SimulationEvent] {
        guard let allowed = gate.allowedColor else { return [] }

        if state.shuriken[shurikenIndex].color != allowed {
            // JAM
            state.shuriken[shurikenIndex].isJammed = true
            state.shuriken[shurikenIndex].jammedAtRow = gate.row
            let lane = state.shuriken[shurikenIndex].lane
            state.jamCounts[lane, default: 0] += 1

            let jamCount = state.jamCounts[lane, default: 0]

            if jamCount >= GameConstants.jamThreshold {
                state.phase = .failed
                state.failReason = .overflow(lane: lane)
                state.overflowMargin = 0
            } else {
                state.overflowMargin = GameConstants.jamThreshold - jamCount
            }

            return [.gateTriggered(type: .color, lane: gate.lane, row: gate.row, result: .jam)]
        }

        return [.gateTriggered(type: .color, lane: gate.lane, row: gate.row, result: .pass)]
    }

    private func applyToggleGate(gate: Gate, shurikenIndex: Int, state: inout GameState) -> [SimulationEvent] {
        guard let cycle = gate.colorCycle, !cycle.isEmpty else { return [] }
        let cycleN = gate.cycleEveryNSpawns ?? GameConstants.defaultToggleCycleEveryNSpawns
        // Use per-gate encounter count so the gate actually cycles through colors
        // as shuriken pass through it, regardless of global spawn timing.
        let gateKey = "\(gate.lane)_\(gate.row)"
        let encounters = state.gateEncounters[gateKey, default: 0]
        state.gateEncounters[gateKey] = encounters + 1
        let colorIndex = (encounters / cycleN) % cycle.count
        let allowedColor = cycle[colorIndex]

        if state.shuriken[shurikenIndex].color != allowedColor {
            // JAM
            state.shuriken[shurikenIndex].isJammed = true
            state.shuriken[shurikenIndex].jammedAtRow = gate.row
            let lane = state.shuriken[shurikenIndex].lane
            state.jamCounts[lane, default: 0] += 1

            let jamCount = state.jamCounts[lane, default: 0]
            if jamCount >= GameConstants.jamThreshold {
                state.phase = .failed
                state.failReason = .overflow(lane: lane)
                state.overflowMargin = 0
            } else {
                state.overflowMargin = GameConstants.jamThreshold - jamCount
            }

            return [.gateTriggered(type: .toggle, lane: gate.lane, row: gate.row, result: .jam)]
        }

        return [.gateTriggered(type: .toggle, lane: gate.lane, row: gate.row, result: .pass)]
    }

    private func applyPaintGate(gate: Gate, shurikenIndex: Int, state: inout GameState) -> [SimulationEvent] {
        guard let from = gate.fromColor, let to = gate.toColor else { return [] }

        if state.shuriken[shurikenIndex].color == from {
            state.shuriken[shurikenIndex].color = to
            return [.gateTriggered(type: .paint, lane: gate.lane, row: gate.row, result: .paint)]
        }

        return [.gateTriggered(type: .paint, lane: gate.lane, row: gate.row, result: .pass)]
    }

    // MARK: - Operator Effects

    private func applyOperatorEffect(
        shurikenIndex: Int,
        entryLane: Int,
        row: Int,
        state: inout GameState
    ) -> [SimulationEvent] {
        // Find operator at this row that's adjacent to the entry lane
        // One deflection per row per shuriken: check ONLY entry-lane boundary slot
        let adjacentSlots = BoundarySlot.slotsAdjacentToLane(entryLane)

        for slot in adjacentSlots {
            if let opIdx = state.operators.firstIndex(where: { $0.row == row && $0.slot == slot && !$0.isExpired }) {
                // Deflect: shift to the other lane
                let (left, right) = slot.adjacentLanes
                let newLane = (entryLane == left) ? right : left
                state.shuriken[shurikenIndex].lane = newLane

                // Decrement charges
                state.operators[opIdx].charges -= 1

                let event = SimulationEvent.operatorTriggered(
                    row: row,
                    slot: slot,
                    shurikenId: state.shuriken[shurikenIndex].id,
                    remainingCharges: state.operators[opIdx].charges
                )

                // Remove expired operators
                if state.operators[opIdx].isExpired {
                    state.operators.remove(at: opIdx)
                }

                return [event] // One deflection per row
            }
        }

        return []
    }

    // MARK: - Helpers

    private func rowForProgress(_ progress: Double) -> Int {
        let clamped = max(0, min(1.0, progress))
        return Int(clamped * Double(GameConstants.rowCount))
    }

    private func progressPerTick(_ dt: Double) -> Double {
        dt / (GameConstants.shurikenRowTravelTime * Double(GameConstants.rowCount))
    }
}
