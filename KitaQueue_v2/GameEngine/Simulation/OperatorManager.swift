import Foundation

/// Manages operator placement, cap enforcement, and undo.
struct OperatorManager: Sendable {

    /// Attempt to place an operator. Returns success.
    func placeOperator(row: Int, slot: BoundarySlot, state: inout GameState) -> Bool {
        // Check cap
        let activeCount = state.operators.count
        guard activeCount < GameConstants.activeOperatorCap else { return false }

        // Check bounds
        guard row >= 1 && row <= GameConstants.rowCount else { return false }

        // Check no duplicate at same position
        guard !state.operators.contains(where: { $0.row == row && $0.slot == slot }) else { return false }

        let op = Operator(
            id: state.nextOperatorId,
            row: row,
            slot: slot,
            charges: GameConstants.chargesPerOperator,
            placementOrder: state.totalOperatorsPlaced,
            placementTimestep: state.timestep
        )

        state.operators.append(op)
        state.nextOperatorId += 1
        state.totalOperatorsPlaced += 1
        return true
    }

    /// Remove the most recently placed operator (if still present).
    func undoLastOperator(state: inout GameState) -> Operator? {
        guard let maxOrder = state.operators.map(\.placementOrder).max() else { return nil }
        guard let idx = state.operators.firstIndex(where: { $0.placementOrder == maxOrder }) else { return nil }
        return state.operators.remove(at: idx)
    }

    /// Check if placement is valid (for ghost preview)
    func canPlace(row: Int, slot: BoundarySlot, state: GameState) -> Bool {
        guard row >= 1 && row <= GameConstants.rowCount else { return false }
        guard state.operators.count < GameConstants.activeOperatorCap else { return false }
        guard !state.operators.contains(where: { $0.row == row && $0.slot == slot }) else { return false }
        return true
    }
}
