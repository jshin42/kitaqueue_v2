import Foundation

enum ShurikenColor: String, Codable, CaseIterable, Hashable, Sendable {
    case red, green, yellow, blue

    /// Index matching the lane/bank mapping
    var laneIndex: Int {
        switch self {
        case .red: 0
        case .green: 1
        case .yellow: 2
        case .blue: 3
        }
    }

    /// Bank color for a given lane
    static func bankColor(for lane: Int) -> ShurikenColor {
        switch lane {
        case 0: .red
        case 1: .green
        case 2: .yellow
        case 3: .blue
        default: .red
        }
    }
}
