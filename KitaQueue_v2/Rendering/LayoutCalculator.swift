import CoreGraphics
import UIKit

/// Calculates all positions for the game board, adaptive for iPhone and iPad.
/// All coordinates are in SpriteKit's coordinate system (origin at bottom-left).
struct LayoutCalculator {
    let sceneSize: CGSize

    // MARK: - Device Detection

    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - Board Dimensions

    /// The playable area inset from screen edges
    var boardInset: CGFloat { isIPad ? 80 : 24 }

    /// Total board width
    var boardWidth: CGFloat { sceneSize.width - boardInset * 2 }

    /// Top of the board (below HUD)
    var boardTop: CGFloat { sceneSize.height - topHUDHeight }

    /// Bottom of the board (above bank tray)
    var boardBottom: CGFloat { bankTrayHeight }

    /// Board height
    var boardHeight: CGFloat { boardTop - boardBottom }

    // MARK: - HUD Regions

    var topHUDHeight: CGFloat { isIPad ? 180 : 140 }
    var bankTrayHeight: CGFloat { isIPad ? 120 : 80 }

    // MARK: - Lanes (4 lanes)

    static let laneCount = 4

    /// Width of each lane
    var laneWidth: CGFloat { boardWidth / CGFloat(Self.laneCount) }

    /// Center X position for a lane (0-indexed)
    func laneX(_ lane: Int) -> CGFloat {
        boardInset + laneWidth * (CGFloat(lane) + 0.5)
    }

    /// X positions for lane rail dividers (3 dividers between 4 lanes)
    var laneRailXPositions: [CGFloat] {
        (1..<Self.laneCount).map { boardInset + laneWidth * CGFloat($0) }
    }

    // MARK: - Rows (12 rows, R1 at top, R12 at bottom)

    static let rowCount = 12

    /// Height of each row
    var rowHeight: CGFloat { boardHeight / CGFloat(Self.rowCount) }

    /// Center Y position for a row (1-indexed, R1 = top)
    func rowY(_ row: Int) -> CGFloat {
        boardTop - rowHeight * (CGFloat(row) - 0.5)
    }

    // MARK: - Boundary Slots (A/B/C between lanes)

    /// X position for a boundary slot
    /// Slot A: between lane 0↔1, Slot B: between lane 1↔2, Slot C: between lane 2↔3
    func slotX(_ slotIndex: Int) -> CGFloat {
        boardInset + laneWidth * CGFloat(slotIndex + 1)
    }

    /// Position for an operator slot (row 1-indexed, slot 0-indexed A=0/B=1/C=2)
    func operatorPosition(row: Int, slot: Int) -> CGPoint {
        CGPoint(x: slotX(slot), y: rowY(row))
    }

    // MARK: - Banks (bottom)

    /// Center Y for banks
    var bankCenterY: CGFloat { bankTrayHeight / 2 }

    /// Position for a bank (lane 0-indexed)
    func bankPosition(lane: Int) -> CGPoint {
        CGPoint(x: laneX(lane), y: bankCenterY)
    }

    /// Bank size
    var bankSize: CGSize {
        CGSize(width: laneWidth * 0.8, height: bankTrayHeight * 0.6)
    }

    // MARK: - Spawn Strip (top HUD)

    var spawnStripY: CGFloat { sceneSize.height - topHUDHeight + 30 }

    /// Positions for the NEXT 8 preview slots
    func spawnPreviewPosition(index: Int) -> CGPoint {
        let totalWidth = boardWidth * 0.8
        let slotWidth = totalWidth / 8
        let startX = sceneSize.width / 2 - totalWidth / 2 + slotWidth / 2
        return CGPoint(x: startX + slotWidth * CGFloat(index), y: spawnStripY)
    }

    var spawnPreviewSize: CGSize {
        let slotWidth = boardWidth * 0.8 / 8
        return CGSize(width: slotWidth * 0.7, height: slotWidth * 0.7)
    }

    // MARK: - Counter Badge

    var counterBadgePosition: CGPoint {
        CGPoint(x: sceneSize.width / 2, y: bankTrayHeight + 30)
    }

    // MARK: - Par Badge

    var parBadgePosition: CGPoint {
        CGPoint(x: sceneSize.width - boardInset - 30, y: sceneSize.height - 60)
    }

    // MARK: - Snap Tolerance

    /// Minimum touch target radius
    var snapTolerance: CGFloat { isIPad ? 66 : 44 }

    // MARK: - Shuriken Size

    var shurikenSize: CGSize {
        let s = min(laneWidth * 0.5, rowHeight * 0.7)
        return CGSize(width: s, height: s)
    }

    // MARK: - Operator Size

    var operatorSize: CGSize {
        CGSize(width: laneWidth * 0.4, height: rowHeight * 0.6)
    }

    // MARK: - Ninja Position (decorative, left of board)

    var ninjaPosition: CGPoint {
        CGPoint(x: boardInset / 2, y: boardBottom + boardHeight * 0.3)
    }

    var ninjaSize: CGSize {
        CGSize(width: boardInset * 0.7, height: boardInset * 1.4)
    }
}
