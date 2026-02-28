import SpriteKit

/// A colored bank at the bottom of a lane where shuriken must be deposited.
final class BankNode: SKSpriteNode {
    let lane: Int
    let bankColor: UIColor

    init(lane: Int, color: UIColor, size: CGSize) {
        self.lane = lane
        self.bankColor = color
        let tex = SKTexture.game("bank_slot", size: size, fallbackColor: color)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "bank_\(lane)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Flash glow effect when a shuriken is banked
    func flashGlow() {
        let glow = SKSpriteNode(color: bankColor.withAlphaComponent(0.5), size: CGSize(width: size.width * 1.3, height: size.height * 1.3))
        glow.zPosition = -1
        addChild(glow)
        glow.run(.sequence([
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }
}
