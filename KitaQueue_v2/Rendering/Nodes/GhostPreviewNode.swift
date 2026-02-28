import SpriteKit

/// Semi-transparent preview shown while dragging to place an operator.
final class GhostPreviewNode: SKSpriteNode {
    private var isValid: Bool = true

    init(size: CGSize) {
        let tex = SKTexture.game("ghost_operator", size: size, fallbackColor: .cyan)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "ghostPreview"
        self.alpha = 0.5
        self.zPosition = 35

        // Pulsing animation
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.3, duration: 0.5),
            .fadeAlpha(to: 0.6, duration: 0.5)
        ])
        run(.repeatForever(pulse), withKey: "pulse")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setValid(_ valid: Bool) {
        guard valid != isValid else { return }
        isValid = valid
        if valid {
            color = .clear
            texture = SKTexture.game("ghost_operator", size: size, fallbackColor: .cyan)
        } else {
            texture = SKTexture.game("ghost_operator", size: size, fallbackColor: .red)
        }
    }
}
