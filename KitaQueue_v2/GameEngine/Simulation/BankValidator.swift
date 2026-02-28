import Foundation

/// Validates shuriken banking at the bank row.
struct BankValidator: Sendable {

    /// Check all shuriken that have reached the bank row.
    /// Returns events and mutates state.
    func validateBanking(state: inout GameState) -> [SimulationEvent] {
        var events: [SimulationEvent] = []

        for i in (0..<state.shuriken.count).reversed() {
            let s = state.shuriken[i]
            guard !s.isJammed else { continue }
            guard s.progressY >= 1.0 else { continue }

            // Reached bank row
            let bankColor = ShurikenColor.bankColor(for: s.lane)

            if s.color == bankColor {
                // Successful bank
                state.bankedCount += 1
                events.append(.shurikenBanked(shurikenId: s.id, bankColor: bankColor))
                state.shuriken.remove(at: i)
            } else {
                // Misbank => immediate fail
                state.phase = .failed
                state.failReason = .misbank(shurikenColor: s.color, bankLane: s.lane)
                events.append(.shurikenMisbanked(shurikenId: s.id, color: s.color, bankLane: s.lane))
                return events
            }
        }

        return events
    }
}
