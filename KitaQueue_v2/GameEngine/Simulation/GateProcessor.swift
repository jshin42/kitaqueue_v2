import Foundation

/// Processes gate effects. Delegated to by InteractionProcessor.
/// This file exists for future expansion; current logic is inline in InteractionProcessor.
struct GateProcessor: Sendable {

    /// Get the allowed color for a toggle gate based on encounter count
    static func toggleAllowedColor(gate: Gate, encounterCount: Int) -> ShurikenColor? {
        guard let cycle = gate.colorCycle, !cycle.isEmpty else { return nil }
        let cycleN = gate.cycleEveryNSpawns ?? GameConstants.defaultToggleCycleEveryNSpawns
        let colorIndex = (encounterCount / cycleN) % cycle.count
        return cycle[colorIndex]
    }
}
