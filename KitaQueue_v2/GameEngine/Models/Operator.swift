import Foundation

struct Operator: Identifiable, Hashable, Sendable {
    let id: Int
    let row: Int             // 1-indexed
    let slot: BoundarySlot
    var charges: Int         // Starts at K=3, decrements per trigger
    let placementOrder: Int  // For undo tracking
    let placementTimestep: Int

    var isExpired: Bool { charges <= 0 }
}
