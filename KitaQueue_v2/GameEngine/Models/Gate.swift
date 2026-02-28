import Foundation

enum GateType: String, Codable, Hashable, Sendable {
    case color
    case toggle
    case paint
}

struct Gate: Codable, Hashable, Sendable {
    let type: GateType
    let lane: Int   // 0-3
    let row: Int    // 1-indexed

    // Color gate params
    var allowedColor: ShurikenColor?

    // Toggle gate params
    var colorCycle: [ShurikenColor]?
    var cycleEveryNSpawns: Int?

    // Paint gate params
    var fromColor: ShurikenColor?
    var toColor: ShurikenColor?
}
