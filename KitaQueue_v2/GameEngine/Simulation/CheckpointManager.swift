import Foundation

/// Maintains rolling GameState snapshots for Fix It resume.
/// Checkpoint is saved at each row boundary interaction.
final class CheckpointManager: @unchecked Sendable {
    private var checkpoint: GameState?

    func saveCheckpoint(_ state: GameState) {
        checkpoint = state
    }

    func restoreCheckpoint() -> GameState? {
        checkpoint
    }

    func clear() {
        checkpoint = nil
    }

    /// Apply overflow fix: clear 1 jam in the failing lane
    static func applyOverflowFix(_ state: inout GameState, lane: Int) {
        // Find the most recent jammed shuriken in this lane
        if let idx = state.shuriken.lastIndex(where: { $0.isJammed && $0.lane == lane }) {
            state.shuriken.remove(at: idx)
            state.jamCounts[lane, default: 0] = max(0, (state.jamCounts[lane, default: 0]) - 1)
        }
        state.phase = .playing
        state.failReason = nil
        state.overflowMargin = nil
    }

    /// Apply misbank fix: remove last placed operator
    static func applyMisbankFix(_ state: inout GameState) {
        // Remove the last operator placed (by placementOrder)
        if let maxOrder = state.operators.map(\.placementOrder).max() {
            state.operators.removeAll { $0.placementOrder == maxOrder }
        }
        state.phase = .playing
        state.failReason = nil
    }
}
