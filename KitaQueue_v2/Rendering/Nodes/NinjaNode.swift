import SpriteKit

/// Decorative ninja mascot positioned left of the lane grid.
final class NinjaNode: SKSpriteNode {
    init(size: CGSize) {
        let tex = SKTexture.game("ninja", size: size, fallbackColor: .lightGray)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "ninja"
        self.alpha = 0.6
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
