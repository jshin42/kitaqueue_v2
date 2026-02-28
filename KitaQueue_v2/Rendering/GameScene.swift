import SpriteKit

/// Main SpriteKit scene for gameplay.
/// Renders the board: lanes, banks, gates, shuriken, operators, HUD.
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

    // MARK: - Layout

    private var layout: LayoutCalculator {
        LayoutCalculator(sceneSize: size)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.15, alpha: 1.0) // Dark indigo

        // Set up node hierarchy
        addChild(backgroundLayer)
        addChild(laneLayer)
        addChild(gateLayer)
        addChild(operatorLayer)
        addChild(shurikenLayer)
        addChild(hudLayer)
        addChild(overlayLayer)

        for layer in [backgroundLayer, laneLayer, gateLayer, operatorLayer, shurikenLayer, hudLayer, overlayLayer] {
            layer.zPosition = CGFloat([backgroundLayer, laneLayer, gateLayer, operatorLayer, shurikenLayer, hudLayer, overlayLayer].firstIndex(of: layer) ?? 0) * 10
        }

        setupBoard()
    }

    // MARK: - Board Setup

    func setupBoard() {
        // Clear existing
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

        // Banks (4)
        let bankColors: [UIColor] = [.systemRed, .systemGreen, .systemYellow, .systemBlue]
        for lane in 0..<LayoutCalculator.laneCount {
            let bank = BankNode(lane: lane, color: bankColors[lane], size: l.bankSize)
            bank.position = l.bankPosition(lane: lane)
            laneLayer.addChild(bank)
        }

        // Ninja mascot (decorative)
        if l.boardInset > 40 { // Only show if there's room
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
        let counter = SKLabelNode(text: "0/24")
        counter.fontName = "AvenirNext-Bold"
        counter.fontSize = 16
        counter.fontColor = .white
        counter.position = l.counterBadgePosition
        counter.name = "counterLabel"
        counterLabel = counter
        hudLayer.addChild(counter)

        // HUD: Par badge
        let par = SKLabelNode(text: "0/6")
        par.fontName = "AvenirNext-DemiBold"
        par.fontSize = 14
        par.fontColor = .green
        par.position = l.parBadgePosition
        par.name = "parBadge"
        parBadgeLabel = par
        hudLayer.addChild(par)

        // Board border lines (top and bottom of play area)
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

        // Strip background
        let stripWidth = l.boardWidth * 0.85
        let stripHeight: CGFloat = 36
        let stripBg = SKShapeNode(rectOf: CGSize(width: stripWidth, height: stripHeight), cornerRadius: 8)
        stripBg.fillColor = .white.withAlphaComponent(0.05)
        stripBg.strokeColor = .white.withAlphaComponent(0.1)
        stripBg.lineWidth = 1
        stripBg.position = CGPoint(x: size.width / 2, y: l.spawnStripY)
        hudLayer.addChild(stripBg)

        // "NEXT" label
        let nextLabel = SKLabelNode(text: "NEXT")
        nextLabel.fontName = "AvenirNext-DemiBold"
        nextLabel.fontSize = 10
        nextLabel.fontColor = .white.withAlphaComponent(0.4)
        nextLabel.position = CGPoint(x: size.width / 2 - stripWidth / 2 + 24, y: l.spawnStripY - 4)
        hudLayer.addChild(nextLabel)

        // 8 preview slots
        for i in 0..<8 {
            let slotNode = SKSpriteNode(color: .clear, size: l.spawnPreviewSize)
            slotNode.position = l.spawnPreviewPosition(index: i)
            hudLayer.addChild(slotNode)
            spawnPreviewNodes.append(slotNode)
        }
    }

    // MARK: - Update

    func updateCounter(banked: Int, total: Int) {
        counterLabel?.text = "\(banked)/\(total)"
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

    // MARK: - Touch Handling (will be expanded in M4)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Will handle operator placement in M4
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ghost preview in M4
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Commit placement in M4
    }
}
