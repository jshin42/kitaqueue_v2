import SpriteKit

/// Visual representation of a shuriken on the game board.
final class ShurikenNode: SKSpriteNode {
    let shurikenId: Int
    private(set) var shurikenColor: ShurikenColor

    init(id: Int, color: ShurikenColor, size: CGSize) {
        self.shurikenId = id
        self.shurikenColor = color
        let tex = SKTexture.game("shuriken_\(color.rawValue)", size: size, fallbackColor: color.uiColor)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "shuriken_\(id)"

        // Gentle continuous rotation
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        run(.repeatForever(rotate))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func updateColor(_ newColor: ShurikenColor) {
        guard newColor != shurikenColor else { return }
        shurikenColor = newColor
        texture = SKTexture.game("shuriken_\(newColor.rawValue)", size: size, fallbackColor: newColor.uiColor)
    }

    func showJammed() {
        removeAllActions()
        // Red overlay + shake
        let overlay = SKSpriteNode(color: UIColor.red.withAlphaComponent(0.5), size: size)
        overlay.name = "jamOverlay"
        addChild(overlay)

        let shake = SKAction.sequence([
            .moveBy(x: -3, y: 0, duration: 0.05),
            .moveBy(x: 6, y: 0, duration: 0.05),
            .moveBy(x: -6, y: 0, duration: 0.05),
            .moveBy(x: 3, y: 0, duration: 0.05),
        ])
        run(.repeat(shake, count: 3))
    }
}

// MARK: - ShurikenColor UI Extension

extension ShurikenColor {
    var uiColor: UIColor {
        switch self {
        case .red: .systemRed
        case .green: .systemGreen
        case .yellow: .systemYellow
        case .blue: .systemBlue
        }
    }
}
