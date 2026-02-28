import Foundation
import CryptoKit

/// Produces a deterministic hash of GameState for verification.
enum GameStateHasher {
    static func hash(_ state: GameState) -> String {
        var hasher = SHA256()

        // Phase
        hasher.update(data: Data("\(state.phase)".utf8))

        // Shuriken state
        for s in state.shuriken.sorted(by: { $0.id < $1.id }) {
            hasher.update(data: Data("s\(s.id):\(s.color):\(s.lane):\(s.isJammed)".utf8))
        }

        // Banking
        hasher.update(data: Data("banked:\(state.bankedCount)".utf8))

        // Operators
        for op in state.operators.sorted(by: { $0.id < $1.id }) {
            hasher.update(data: Data("op\(op.id):\(op.row):\(op.slot):\(op.charges)".utf8))
        }

        // Jams
        for (lane, count) in state.jamCounts.sorted(by: { $0.key < $1.key }) {
            hasher.update(data: Data("jam\(lane):\(count)".utf8))
        }

        // Counters
        hasher.update(data: Data("placed:\(state.totalOperatorsPlaced)".utf8))
        hasher.update(data: Data("spawned:\(state.spawnedCount)".utf8))

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
