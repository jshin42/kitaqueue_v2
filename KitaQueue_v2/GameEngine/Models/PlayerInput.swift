import Foundation

enum PlayerInput: Codable, Hashable, Sendable {
    case place(row: Int, slot: BoundarySlot, timestep: Int)
    case undo(timestep: Int)
}
