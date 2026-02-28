import SpriteKit

/// Visual representation of a placed deflect operator.
final class OperatorNode: SKSpriteNode {
    let operatorId: Int
    let row: Int
    let slot: BoundarySlot
    private var chargePips: [SKSpriteNode] = []

    init(id: Int, row: Int, slot: BoundarySlot, size: CGSize) {
        self.operatorId = id
        self.row = row
        self.slot = slot
        let tex = SKTexture.game("operator_active", size: size, fallbackColor: .cyan)
        super.init(texture: tex, color: .clear, size: size)
        self.name = "operator_\(id)"
        self.zPosition = 30

        // Add charge pips
        setupChargePips(charges: GameConstants.chargesPerOperator)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupChargePips(charges: Int) {
        chargePips.forEach { $0.removeFromParent() }
        chargePips.removeAll()

        let pipSize: CGFloat = 5
        let spacing: CGFloat = 8
        let totalWidth = CGFloat(charges - 1) * spacing
        let startX = -totalWidth / 2

        for i in 0..<charges {
            let pip = SKSpriteNode(color: .white, size: CGSize(width: pipSize, height: pipSize))
            pip.position = CGPoint(x: startX + CGFloat(i) * spacing, y: -size.height / 2 - 8)
            pip.name = "pip_\(i)"
            addChild(pip)
            chargePips.append(pip)
        }
    }

    func updateCharges(_ remaining: Int) {
        for (i, pip) in chargePips.enumerated() {
            pip.alpha = i < remaining ? 1.0 : 0.2
        }
    }

    func showTriggerFlash(color: UIColor) {
        let flash = SKSpriteNode(color: color, size: CGSize(width: size.width * 1.5, height: size.height * 1.5))
        flash.zPosition = -1
        addChild(flash)
        flash.run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
    }

    func animateRemoval() {
        run(.sequence([
            .group([
                .fadeOut(withDuration: 0.2),
                .scale(to: 0.5, duration: 0.2)
            ]),
            .removeFromParent()
        ]))
    }
}
