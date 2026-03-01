import SpriteKit

/// Creates particle effects for game events.
/// Uses SKEmitterNode for premium effects; falls back to simple sprites when reduceMotion is on.
@MainActor
enum ParticleFactory {

    private static var reduceMotion: Bool {
        PersistenceService.shared.loadSettings().reduceMotion
    }

    // MARK: - Spark Hit (operator trigger)

    static func sparkHit(at position: CGPoint, color: UIColor) -> SKNode {
        if reduceMotion {
            return simpleFlash(at: position, color: color, size: 20, duration: 0.15)
        }

        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 12
        emitter.particleLifetime = 0.3
        emitter.particleLifetimeRange = 0.1
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 40
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -3.0
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = -0.5
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleTexture = SKTexture.game("spark", size: CGSize(width: 8, height: 8), fallbackColor: color)
        emitter.position = position
        emitter.zPosition = 50

        emitter.run(.sequence([
            .wait(forDuration: 0.5),
            .removeFromParent()
        ]))
        return emitter
    }

    // MARK: - Confetti (win celebration)

    static func confetti(in sceneSize: CGSize) -> SKNode {
        if reduceMotion {
            // Simple flash instead of confetti
            return simpleFlash(
                at: CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2),
                color: .yellow, size: sceneSize.width, duration: 0.3
            )
        }

        let container = SKNode()
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemYellow, .systemBlue, .orange, .cyan, .purple]

        for _ in 0..<50 {
            let piece = SKSpriteNode(color: colors.randomElement()!, size: CGSize(width: 6, height: 10))
            piece.position = CGPoint(
                x: CGFloat.random(in: 0...sceneSize.width),
                y: sceneSize.height + CGFloat.random(in: 20...60)
            )
            piece.zPosition = 100

            let fallDuration = Double.random(in: 1.0...2.0)
            let swayAmount = CGFloat.random(in: -30...30)

            piece.run(.sequence([
                .group([
                    .moveTo(y: -20, duration: fallDuration),
                    .moveBy(x: swayAmount, y: 0, duration: fallDuration),
                    .rotate(byAngle: CGFloat.random(in: -6...6), duration: fallDuration),
                    .sequence([
                        .wait(forDuration: fallDuration * 0.6),
                        .fadeOut(withDuration: fallDuration * 0.4)
                    ])
                ]),
                .removeFromParent()
            ]))
            container.addChild(piece)
        }
        return container
    }

    // MARK: - Bank Glow (shuriken banked)

    static func bankGlow(at position: CGPoint, color: UIColor) -> SKNode {
        if reduceMotion {
            return simpleFlash(at: position, color: color, size: 40, duration: 0.2)
        }

        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 40
        emitter.numParticlesToEmit = 8
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.1
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.4
        emitter.particleScaleSpeed = 0.3
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleTexture = SKTexture.game("spark", size: CGSize(width: 8, height: 8), fallbackColor: color)
        emitter.position = position
        emitter.zPosition = 40

        emitter.run(.sequence([
            .wait(forDuration: 0.6),
            .removeFromParent()
        ]))
        return emitter
    }

    // MARK: - Slash Trail (deflected shuriken)

    static func slashTrail(from start: CGPoint, to end: CGPoint, color: UIColor) -> SKNode {
        if reduceMotion { return SKNode() }

        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 60
        emitter.numParticlesToEmit = 10
        emitter.particleLifetime = 0.25
        emitter.particleLifetimeRange = 0.05
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -3.0
        emitter.particleScale = 0.15
        emitter.particleScaleSpeed = -0.3
        emitter.particleSpeed = 0
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleTexture = SKTexture.game("spark", size: CGSize(width: 6, height: 6), fallbackColor: color)
        emitter.position = start
        emitter.zPosition = 45

        let dx = end.x - start.x
        let dy = end.y - start.y
        emitter.emissionAngle = atan2(dy, dx)
        emitter.emissionAngleRange = 0.2

        emitter.run(.sequence([
            .move(to: end, duration: 0.1),
            .wait(forDuration: 0.3),
            .removeFromParent()
        ]))
        return emitter
    }

    // MARK: - Fail Flash

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

    // MARK: - Camera Nudge (placement confirmation)

    static func cameraNudge(scene: SKScene) {
        guard !reduceMotion else { return }

        let nudge = SKAction.sequence([
            .moveBy(x: 0, y: 3, duration: 0.04),
            .moveBy(x: 0, y: -6, duration: 0.06),
            .moveBy(x: 0, y: 3, duration: 0.04),
        ])
        scene.run(nudge)
    }

    // MARK: - Ghost Glow Pulse

    static func ghostGlowAction() -> SKAction {
        .repeatForever(
            .sequence([
                .fadeAlpha(to: 0.7, duration: 0.6),
                .fadeAlpha(to: 0.3, duration: 0.6)
            ])
        )
    }

    // MARK: - Helper

    private static func simpleFlash(at position: CGPoint, color: UIColor, size: CGFloat, duration: TimeInterval) -> SKNode {
        let node = SKSpriteNode(color: color, size: CGSize(width: size, height: size))
        node.position = position
        node.zPosition = 50
        node.run(.sequence([
            .group([
                .scale(to: 1.5, duration: duration),
                .fadeOut(withDuration: duration)
            ]),
            .removeFromParent()
        ]))
        return node
    }
}
