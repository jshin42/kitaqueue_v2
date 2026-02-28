import SpriteKit

/// Creates particle effects for game events.
/// M2: Simple flash/glow effects. M15: Full SKEmitterNode particle systems.
enum ParticleFactory {

    /// Spark burst when operator triggers
    static func sparkHit(at position: CGPoint, color: UIColor) -> SKNode {
        let node = SKSpriteNode(color: color, size: CGSize(width: 20, height: 20))
        node.position = position
        node.zPosition = 50
        node.run(.sequence([
            .group([
                .scale(to: 2.0, duration: 0.15),
                .fadeOut(withDuration: 0.15)
            ]),
            .removeFromParent()
        ]))
        return node
    }

    /// Confetti burst on win
    static func confetti(in sceneSize: CGSize) -> SKNode {
        let container = SKNode()
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemYellow, .systemBlue, .orange, .cyan]
        for _ in 0..<30 {
            let piece = SKSpriteNode(color: colors.randomElement()!, size: CGSize(width: 6, height: 6))
            piece.position = CGPoint(x: CGFloat.random(in: 0...sceneSize.width), y: sceneSize.height + 20)
            piece.zPosition = 100
            let fallDuration = Double.random(in: 0.8...1.5)
            piece.run(.sequence([
                .group([
                    .moveTo(y: -20, duration: fallDuration),
                    .rotate(byAngle: CGFloat.random(in: -4...4), duration: fallDuration),
                    .sequence([
                        .wait(forDuration: fallDuration * 0.7),
                        .fadeOut(withDuration: fallDuration * 0.3)
                    ])
                ]),
                .removeFromParent()
            ]))
            container.addChild(piece)
        }
        return container
    }

    /// Glow flash on bank deposit
    static func bankGlow(at position: CGPoint, color: UIColor) -> SKNode {
        let glow = SKSpriteNode(color: color.withAlphaComponent(0.6), size: CGSize(width: 50, height: 50))
        glow.position = position
        glow.zPosition = 40
        glow.run(.sequence([
            .group([
                .scale(to: 1.5, duration: 0.2),
                .fadeOut(withDuration: 0.2)
            ]),
            .removeFromParent()
        ]))
        return glow
    }

    /// Screen flash on fail
    static func failFlash(in sceneSize: CGSize) -> SKNode {
        let flash = SKSpriteNode(color: UIColor.red.withAlphaComponent(0.3), size: sceneSize)
        flash.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        flash.zPosition = 90
        flash.run(.sequence([
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))
        return flash
    }
}
