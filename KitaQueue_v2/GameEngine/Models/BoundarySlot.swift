import Foundation

/// Boundary slots between lanes where operators can be placed.
/// A: between lane 0↔1, B: between lane 1↔2, C: between lane 2↔3
enum BoundarySlot: Int, Codable, CaseIterable, Hashable, Sendable {
    case a = 0, b = 1, c = 2

    /// The two lanes adjacent to this boundary slot
    var adjacentLanes: (left: Int, right: Int) {
        switch self {
        case .a: (0, 1)
        case .b: (1, 2)
        case .c: (2, 3)
        }
    }

    /// Returns the slot adjacent to a given lane, if the shuriken is in that lane
    static func slot(adjacentTo lane: Int, side: DeflectSide) -> BoundarySlot? {
        switch (lane, side) {
        case (0, .right): .a
        case (1, .left):  .a
        case (1, .right): .b
        case (2, .left):  .b
        case (2, .right): .c
        case (3, .left):  .c
        default: nil
        }
    }

    /// Returns which slot a shuriken in the given lane would check
    /// (shuriken checks the slot on its boundary side)
    static func slotsAdjacentToLane(_ lane: Int) -> [BoundarySlot] {
        var slots: [BoundarySlot] = []
        if lane > 0 {
            slots.append(BoundarySlot(rawValue: lane - 1)!)
        }
        if lane < GameConstants.laneCount - 1 {
            slots.append(BoundarySlot(rawValue: lane)!)
        }
        return slots
    }

    enum DeflectSide {
        case left, right
    }
}
