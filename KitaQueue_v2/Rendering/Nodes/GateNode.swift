import SpriteKit

/// Visual representation of a gate on the game board.
final class GateNode: SKSpriteNode {
    let gate: Gate
    private var colorIndicator: SKSpriteNode?

    init(gate: Gate, size: CGSize) {
        self.gate = gate

        // Gate housing bar
        let color: UIColor
        switch gate.type {
        case .color:
            color = gate.allowedColor?.uiColor ?? .gray
        case .toggle:
            color = gate.colorCycle?.first?.uiColor ?? .gray
        case .paint:
            color = gate.toColor?.uiColor ?? .purple
        }

        let tex = SKTexture.game("gate_\(gate.type.rawValue)", size: size, fallbackColor: color)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "gate_\(gate.lane)_\(gate.row)"
        self.zPosition = 20

        // Color indicator dot
        let dotSize: CGFloat = 14
        let dot = SKSpriteNode(color: color, size: CGSize(width: dotSize, height: dotSize))
        dot.position = CGPoint(x: 0, y: 0)
        dot.name = "gateColorDot"
        addChild(dot)
        colorIndicator = dot
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Update the color indicator (for toggle gates that cycle)
    func updateAllowedColor(_ color: ShurikenColor) {
        colorIndicator?.color = color.uiColor
    }

    /// Flash when gate blocks a shuriken (jam)
    func showBlockFlash() {
        let flash = SKSpriteNode(color: UIColor.red.withAlphaComponent(0.6), size: CGSize(width: size.width * 1.3, height: size.height * 1.5))
        flash.zPosition = -1
        addChild(flash)
        flash.run(.sequence([
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ]))
    }

    /// Flash when paint gate converts a shuriken
    func showPaintFlash(toColor: ShurikenColor) {
        let flash = SKSpriteNode(color: toColor.uiColor.withAlphaComponent(0.5), size: CGSize(width: size.width * 1.3, height: size.height * 1.5))
        flash.zPosition = -1
        addChild(flash)
        flash.run(.sequence([
            .fadeOut(withDuration: 0.25),
            .removeFromParent()
        ]))
    }
}
