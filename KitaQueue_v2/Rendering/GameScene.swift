import SpriteKit

/// Main SpriteKit scene for gameplay.
/// Renders the board: lanes, banks, gates, shuriken, operators, HUD.
/// Handles touch input for operator placement with ghost preview.
final class GameScene: SKScene {

    weak var coordinator: GameSceneCoordinator?

    // MARK: - Node Layers

    private let backgroundLayer = SKNode()
    private let laneLayer = SKNode()
    private let gateLayer = SKNode()
    private let operatorLayer = SKNode()
    private let shurikenLayer = SKNode()
    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()

    // MARK: - HUD Nodes

    private var counterLabel: SKLabelNode?
    private var parBadgeLabel: SKLabelNode?
    private var spawnPreviewNodes: [SKSpriteNode] = []

    // MARK: - Touch State

    private var ghostPreview: GhostPreviewNode?
    private var currentSnapRow: Int?
    private var currentSnapSlot: BoundarySlot?

    // MARK: - Update Tracking

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Layout

    private var layout: LayoutCalculator {
        LayoutCalculator(sceneSize: size)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.15, alpha: 1.0)

        addChild(backgroundLayer)
        addChild(laneLayer)
        addChild(gateLayer)
        addChild(operatorLayer)
        addChild(shurikenLayer)
        addChild(hudLayer)
        addChild(overlayLayer)

        for (index, layer) in [backgroundLayer, laneLayer, gateLayer, operatorLayer, shurikenLayer, hudLayer, overlayLayer].enumerated() {
            layer.zPosition = CGFloat(index) * 10
        }

        setupBoard()
    }

    // MARK: - Board Setup

    func setupBoard() {
        laneLayer.removeAllChildren()
        gateLayer.removeAllChildren()
        operatorLayer.removeAllChildren()
        shurikenLayer.removeAllChildren()
        hudLayer.removeAllChildren()

        let l = layout

        // Lane rails (3 dividers)
        for x in l.laneRailXPositions {
            let railSize = CGSize(width: 2, height: l.boardHeight)
            let rail = SKSpriteNode(
                texture: .game("rail", size: railSize, fallbackColor: .gray),
                size: railSize
            )
            rail.position = CGPoint(x: x, y: l.boardBottom + l.boardHeight / 2)
            laneLayer.addChild(rail)
        }

        // Operator slot hints (36 = 12 rows x 3 slots)
        for row in 1...LayoutCalculator.rowCount {
            for slot in 0..<3 {
                let hintSize = CGSize(width: 12, height: 12)
                let hint = SKSpriteNode(
                    texture: .game("slot_hint", size: hintSize, fallbackColor: .gray),
                    size: hintSize
                )
                hint.position = l.operatorPosition(row: row, slot: slot)
                hint.alpha = 0.3
                laneLayer.addChild(hint)
            }
        }

        // Gates (from level data)
        if let gates = coordinator?.simulation?.levelData.gates {
            for gate in gates {
                let gateNode = GateNode(gate: gate, size: l.gateSize)
                gateNode.position = l.gatePosition(lane: gate.lane, row: gate.row)
                gateLayer.addChild(gateNode)
            }
        }

        // Banks (4)
        let bankColors: [UIColor] = [.systemRed, .systemGreen, .systemYellow, .systemBlue]
        for lane in 0..<LayoutCalculator.laneCount {
            let bank = BankNode(lane: lane, color: bankColors[lane], size: l.bankSize)
            bank.position = l.bankPosition(lane: lane)
            laneLayer.addChild(bank)
        }

        // Ninja mascot (decorative)
        if l.boardInset > 40 {
            let ninjaSize = l.ninjaSize
            let ninja = NinjaNode(size: ninjaSize)
            ninja.position = l.ninjaPosition
            laneLayer.addChild(ninja)
        }

        // HUD: Title
        let titleLabel = SKLabelNode(text: "KATA QUEUE")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = .orange
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 30)
        hudLayer.addChild(titleLabel)

        // HUD: Spawn strip
        setupSpawnStrip()

        // HUD: Counter badge
        let counter = SKLabelNode(text: "0/\(coordinator?.totalShuriken ?? 24)")
        counter.fontName = "AvenirNext-Bold"
        counter.fontSize = 16
        counter.fontColor = .white
        counter.position = l.counterBadgePosition
        counter.name = "counterLabel"
        counterLabel = counter
        hudLayer.addChild(counter)

        // HUD: Par badge
        let par = SKLabelNode(text: "0/\(coordinator?.parThreshold ?? 6)")
        par.fontName = "AvenirNext-DemiBold"
        par.fontSize = 14
        par.fontColor = .green
        par.position = l.parBadgePosition
        par.name = "parBadge"
        parBadgeLabel = par
        hudLayer.addChild(par)

        // Board border lines
        let topLine = SKShapeNode(rectOf: CGSize(width: l.boardWidth, height: 1))
        topLine.fillColor = .white.withAlphaComponent(0.1)
        topLine.strokeColor = .clear
        topLine.position = CGPoint(x: size.width / 2, y: l.boardTop)
        laneLayer.addChild(topLine)

        let bottomLine = SKShapeNode(rectOf: CGSize(width: l.boardWidth, height: 1))
        bottomLine.fillColor = .white.withAlphaComponent(0.1)
        bottomLine.strokeColor = .clear
        bottomLine.position = CGPoint(x: size.width / 2, y: l.boardBottom)
        laneLayer.addChild(bottomLine)
    }

    private func setupSpawnStrip() {
        let l = layout
        spawnPreviewNodes.removeAll()

        let stripWidth = l.boardWidth * 0.85
        let stripHeight: CGFloat = 36
        let stripBg = SKShapeNode(rectOf: CGSize(width: stripWidth, height: stripHeight), cornerRadius: 8)
        stripBg.fillColor = .white.withAlphaComponent(0.05)
        stripBg.strokeColor = .white.withAlphaComponent(0.1)
        stripBg.lineWidth = 1
        stripBg.position = CGPoint(x: size.width / 2, y: l.spawnStripY)
        hudLayer.addChild(stripBg)

        let nextLabel = SKLabelNode(text: "NEXT")
        nextLabel.fontName = "AvenirNext-DemiBold"
        nextLabel.fontSize = 10
        nextLabel.fontColor = .white.withAlphaComponent(0.4)
        nextLabel.position = CGPoint(x: size.width / 2 - stripWidth / 2 + 24, y: l.spawnStripY - 4)
        hudLayer.addChild(nextLabel)

        for i in 0..<8 {
            let slotNode = SKSpriteNode(color: .clear, size: l.spawnPreviewSize)
            slotNode.position = l.spawnPreviewPosition(index: i)
            hudLayer.addChild(slotNode)
            spawnPreviewNodes.append(slotNode)
        }
    }

    // MARK: - Clear Dynamic Nodes

    func clearDynamicNodes() {
        shurikenLayer.removeAllChildren()
        operatorLayer.removeAllChildren()
        removeGhostPreview()
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = min(currentTime - lastUpdateTime, 0.1) // Cap to avoid spiral of death
        }
        lastUpdateTime = currentTime

        guard let sim = coordinator?.simulation else { return }

        // Tick the simulation (collects events in pendingEvents)
        sim.tick(dt: dt)

        // Drain events and forward to coordinator for feedback (haptics, SFX, VFX)
        let events = sim.drainEvents()
        if !events.isEmpty {
            coordinator?.processEvents(events)
        }

        // Sync visual state
        syncShurikenPositions()
        updateSpawnPreview()
    }

    // MARK: - Shuriken Sync

    private func syncShurikenPositions() {
        guard let sim = coordinator?.simulation else { return }
        let l = layout
        let activeIds = Set(sim.state.shuriken.map(\.id))

        for shuriken in sim.state.shuriken {
            guard let node = shurikenLayer.childNode(withName: "shuriken_\(shuriken.id)") as? ShurikenNode else { continue }
            guard !shuriken.isJammed else { continue }

            let x = l.laneX(shuriken.lane)
            let y = l.boardTop - CGFloat(shuriken.progressY) * l.boardHeight
            node.position = CGPoint(x: x, y: y)

            // Update color if changed (paint gate)
            if shuriken.color != node.shurikenColor {
                node.updateColor(shuriken.color)
            }
        }

        // Remove nodes for banked shuriken (no longer in state)
        for node in shurikenLayer.children {
            guard let sNode = node as? ShurikenNode else { continue }
            if !activeIds.contains(sNode.shurikenId) && sNode.name?.hasPrefix("removing_") != true {
                sNode.name = "removing_\(sNode.shurikenId)"
                sNode.run(.sequence([
                    .fadeOut(withDuration: 0.15),
                    .removeFromParent()
                ]))
            }
        }
    }

    private func updateSpawnPreview() {
        guard let sim = coordinator?.simulation else { return }
        let colors = sim.spawnPreview(count: GameConstants.spawnPreviewCount)
        let l = layout

        for (i, node) in spawnPreviewNodes.enumerated() {
            if i < colors.count {
                node.texture = SKTexture.game(
                    "shuriken_\(colors[i].rawValue)",
                    size: l.spawnPreviewSize,
                    fallbackColor: colors[i].uiColor
                )
                node.alpha = 1.0
            } else {
                node.texture = nil
                node.color = .clear
                node.alpha = 0.2
            }
        }
    }

    // MARK: - Shuriken Nodes

    func spawnShurikenNode(id: Int, color: ShurikenColor, lane: Int) {
        let l = layout
        let node = ShurikenNode(id: id, color: color, size: l.shurikenSize)
        node.position = CGPoint(x: l.laneX(lane), y: l.boardTop)
        node.alpha = 0
        shurikenLayer.addChild(node)
        node.run(.fadeIn(withDuration: 0.15))
    }

    func flashBank(lane: Int) {
        guard let bank = laneLayer.childNode(withName: "bank_\(lane)") as? BankNode else { return }
        bank.flashGlow()

        let l = layout
        let glow = ParticleFactory.bankGlow(at: l.bankPosition(lane: lane), color: bank.bankColor)
        overlayLayer.addChild(glow)
    }

    func jamShuriken(lane: Int, row: Int) {
        guard let sim = coordinator?.simulation else { return }
        for s in sim.state.shuriken.reversed() where s.isJammed && s.lane == lane {
            if let node = shurikenLayer.childNode(withName: "shuriken_\(s.id)") as? ShurikenNode {
                node.showJammed()
                break
            }
        }

        // Flash the gate that caused the jam
        if let gateNode = gateLayer.childNode(withName: "gate_\(lane)_\(row)") as? GateNode {
            gateNode.showBlockFlash()
        }
    }

    func flashGatePaint(lane: Int, row: Int, toColor: ShurikenColor) {
        if let gateNode = gateLayer.childNode(withName: "gate_\(lane)_\(row)") as? GateNode {
            gateNode.showPaintFlash(toColor: toColor)
        }
    }

    // MARK: - Operator Nodes

    func addOperatorNode(id: Int, row: Int, slot: BoundarySlot, position: CGPoint, size: CGSize) {
        let node = OperatorNode(id: id, row: row, slot: slot, size: size)
        node.position = position
        node.alpha = 0
        node.setScale(0.5)
        operatorLayer.addChild(node)

        node.run(.group([
            .fadeIn(withDuration: 0.15),
            .scale(to: 1.0, duration: 0.15)
        ]))
    }

    func removeLastOperatorNode() {
        let opNodes = operatorLayer.children.compactMap { $0 as? OperatorNode }
        guard let lastNode = opNodes.max(by: { $0.operatorId < $1.operatorId }) else { return }
        lastNode.animateRemoval()
    }

    func triggerOperatorNode(row: Int, slot: BoundarySlot, remainingCharges: Int) {
        let opNodes = operatorLayer.children.compactMap { $0 as? OperatorNode }
        guard let node = opNodes.first(where: { $0.row == row && $0.slot == slot }) else { return }

        node.updateCharges(remainingCharges)
        node.showTriggerFlash(color: .cyan)

        let spark = ParticleFactory.sparkHit(at: node.position, color: .cyan)
        overlayLayer.addChild(spark)

        if remainingCharges <= 0 {
            node.animateRemoval()
        }
    }

    // MARK: - VFX

    func showFailFlash() {
        let flash = ParticleFactory.failFlash(in: size)
        overlayLayer.addChild(flash)
    }

    func showConfetti() {
        let confetti = ParticleFactory.confetti(in: size)
        overlayLayer.addChild(confetti)
    }

    // MARK: - HUD Updates

    func updateCounter(banked: Int, total: Int) {
        counterLabel?.text = "\(banked)/\(total)"
        counterLabel?.run(.sequence([
            .scale(to: 1.3, duration: 0.1),
            .scale(to: 1.0, duration: 0.1)
        ]))
    }

    func updateParBadge(used: Int, threshold: Int) {
        parBadgeLabel?.text = "\(used)/\(threshold)"
        if used <= threshold {
            parBadgeLabel?.fontColor = .green
        } else if used <= threshold + 2 {
            parBadgeLabel?.fontColor = .yellow
        } else {
            parBadgeLabel?.fontColor = .red
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard coordinator?.gamePhase == .playing else { return }
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if let snap = snapToGrid(point: point) {
            showGhostPreview(row: snap.row, slot: snap.slot)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard coordinator?.gamePhase == .playing else { return }
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if let snap = snapToGrid(point: point) {
            if snap.row != currentSnapRow || snap.slot != currentSnapSlot {
                showGhostPreview(row: snap.row, slot: snap.slot)
            }
        } else {
            removeGhostPreview()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { removeGhostPreview() }
        guard coordinator?.gamePhase == .playing else { return }

        if let row = currentSnapRow, let slot = currentSnapSlot {
            coordinator?.attemptPlacement(row: row, slot: slot)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeGhostPreview()
    }

    // MARK: - Snap Grid

    private func snapToGrid(point: CGPoint) -> (row: Int, slot: BoundarySlot)? {
        let l = layout

        var bestRow = 1
        var bestRowDist = CGFloat.infinity
        for r in 1...LayoutCalculator.rowCount {
            let dist = abs(point.y - l.rowY(r))
            if dist < bestRowDist {
                bestRowDist = dist
                bestRow = r
            }
        }

        var bestSlotIdx = 0
        var bestSlotDist = CGFloat.infinity
        for s in 0..<3 {
            let dist = abs(point.x - l.slotX(s))
            if dist < bestSlotDist {
                bestSlotDist = dist
                bestSlotIdx = s
            }
        }

        let tolerance = l.snapTolerance
        guard bestRowDist <= tolerance, bestSlotDist <= tolerance else { return nil }
        guard let slot = BoundarySlot(rawValue: bestSlotIdx) else { return nil }
        return (bestRow, slot)
    }

    // MARK: - Ghost Preview

    private func showGhostPreview(row: Int, slot: BoundarySlot) {
        let l = layout
        let pos = l.operatorPosition(row: row, slot: slot.rawValue)

        if ghostPreview == nil {
            let ghost = GhostPreviewNode(size: l.operatorSize)
            ghost.zPosition = 35
            addChild(ghost)
            ghostPreview = ghost
        }

        ghostPreview?.position = pos
        currentSnapRow = row
        currentSnapSlot = slot

        let canPlace = coordinator?.canPlace(row: row, slot: slot) ?? false
        ghostPreview?.setValid(canPlace)
    }

    private func removeGhostPreview() {
        ghostPreview?.removeFromParent()
        ghostPreview = nil
        currentSnapRow = nil
        currentSnapSlot = nil
    }
}
