import Foundation

struct Shuriken: Identifiable, Hashable, Sendable {
    let id: Int
    var color: ShurikenColor
    var lane: Int        // 0-3
    var progressY: Double // 0.0 = top (spawn), 1.0 = bottom (bank row)
    var isJammed: Bool = false
    var jammedAtRow: Int? = nil

    /// Current row position (1-indexed, fractional)
    var currentRow: Double {
        progressY * Double(GameConstants.rowCount)
    }

    /// Integer row the shuriken is approaching (1-indexed)
    var approachingRow: Int {
        min(Int(currentRow) + 1, GameConstants.rowCount)
    }
}
