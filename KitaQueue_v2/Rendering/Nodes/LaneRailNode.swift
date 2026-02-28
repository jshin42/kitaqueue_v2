import SpriteKit

/// A thin vertical divider between two lanes.
final class LaneRailNode: SKSpriteNode {
    init(height: CGFloat) {
        let size = CGSize(width: 2, height: height)
        let tex = SKTexture.game("rail", size: size, fallbackColor: .gray)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "laneRail"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
