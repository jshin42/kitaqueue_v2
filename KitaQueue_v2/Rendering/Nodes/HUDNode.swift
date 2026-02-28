import SpriteKit

/// Container for HUD elements (spawn strip, counter, par badge).
/// Currently managed inline by GameScene; this class reserved for future extraction.
final class HUDNode: SKNode {
    override init() {
        super.init()
        self.name = "hud"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
