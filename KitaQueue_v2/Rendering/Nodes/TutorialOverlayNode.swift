import SpriteKit

/// Overlay node for FTUE tutorial text and end cards.
/// Dims the screen, shows centered text, and dismisses on tap.
final class TutorialOverlayNode: SKNode {

    private let dimBackground: SKSpriteNode
    private let textLabel: SKLabelNode
    private var dismissAction: (() -> Void)?

    init(text: String, sceneSize: CGSize, onDismiss: @escaping () -> Void) {
        self.dismissAction = onDismiss

        // Dim background
        dimBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: sceneSize)
        dimBackground.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        dimBackground.zPosition = 0

        // Text
        textLabel = SKLabelNode(text: text)
        textLabel.fontName = "AvenirNext-Bold"
        textLabel.fontSize = 24
        textLabel.fontColor = .white
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = sceneSize.width * 0.7
        textLabel.verticalAlignmentMode = .center
        textLabel.horizontalAlignmentMode = .center
        textLabel.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        textLabel.zPosition = 1

        super.init()

        self.name = "tutorialOverlay"
        self.zPosition = 200
        self.isUserInteractionEnabled = true

        addChild(dimBackground)
        addChild(textLabel)

        // "Tap to continue" hint
        let hint = SKLabelNode(text: "Tap to continue")
        hint.fontName = "AvenirNext-Regular"
        hint.fontSize = 16
        hint.fontColor = UIColor.white.withAlphaComponent(0.7)
        hint.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.3)
        hint.zPosition = 1
        hint.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.4, duration: 0.8),
            .fadeAlpha(to: 0.7, duration: 0.8)
        ])))
        addChild(hint)

        // Fade in
        alpha = 0
        run(.fadeIn(withDuration: 0.3))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss()
    }

    func dismiss() {
        isUserInteractionEnabled = false
        run(.sequence([
            .fadeOut(withDuration: 0.2),
            .run { [weak self] in
                self?.dismissAction?()
            },
            .removeFromParent()
        ]))
    }
}
