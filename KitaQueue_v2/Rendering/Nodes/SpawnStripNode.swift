import SpriteKit

/// Container for spawn preview strip. Currently managed inline by GameScene.
final class SpawnStripNode: SKNode {
    override init() {
        super.init()
        self.name = "spawnStrip"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
