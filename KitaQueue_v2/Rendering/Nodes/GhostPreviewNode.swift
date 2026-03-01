import SpriteKit

/// Semi-transparent preview shown while dragging to place an operator.
/// Respects accessibility: high contrast uses solid white, reduce motion skips glow.
final class GhostPreviewNode: SKSpriteNode {
    private var isValid: Bool = true
    private var glowNode: SKSpriteNode?

    init(size: CGSize) {
        let settings = PersistenceService.shared.loadSettings()
        let ghostColor: UIColor = settings.highContrastGhost ? .white : .cyan

        let tex = SKTexture.game("ghost_operator", size: size, fallbackColor: ghostColor)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "ghostPreview"
        self.alpha = 0.6
        self.zPosition = 35

        // Glow effect (larger semi-transparent backdrop)
        if !settings.reduceMotion {
            let glow = SKSpriteNode(color: ghostColor.withAlphaComponent(0.2), size: CGSize(width: size.width * 1.8, height: size.height * 1.8))
            glow.zPosition = -1
            addChild(glow)
            glowNode = glow

            // Pulsing glow
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 0.6),
                .fadeAlpha(to: 0.1, duration: 0.6)
            ])), withKey: "glowPulse")
        }

        // Pulsing alpha on main sprite
        run(ParticleFactory.ghostGlowAction(), withKey: "pulse")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setValid(_ valid: Bool) {
        guard valid != isValid else { return }
        isValid = valid

        let settings = PersistenceService.shared.loadSettings()
        let ghostColor: UIColor = settings.highContrastGhost ? .white : .cyan

        if valid {
            color = .clear
            texture = SKTexture.game("ghost_operator", size: size, fallbackColor: ghostColor)
            glowNode?.color = ghostColor.withAlphaComponent(0.2)
        } else {
            texture = SKTexture.game("ghost_operator", size: size, fallbackColor: .red)
            glowNode?.color = UIColor.red.withAlphaComponent(0.2)
        }
    }
}
