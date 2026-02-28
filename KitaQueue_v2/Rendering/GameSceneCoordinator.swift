import SwiftUI
import SpriteKit

/// @Observable bridge between SwiftUI and SpriteKit.
/// Owns the GameScene and will own the GameSimulation (M3).
@Observable
final class GameSceneCoordinator {

    // MARK: - Published State (SwiftUI reads these)

    var bankedCount: Int = 0
    var totalShuriken: Int = 24
    var operatorsUsed: Int = 0
    var parThreshold: Int = 6
    var starRating: Int = 0
    var currentLevel: Int = 1
    var attemptNumber: Int = 1

    enum Phase {
        case idle, preview, playing, tutorialPaused, paused, won, failed
    }
    var gamePhase: Phase = .idle

    // MARK: - Scene

    private(set) var scene: GameScene?

    func makeScene(size: CGSize) -> GameScene {
        let s = GameScene(size: size)
        s.scaleMode = .resizeFill
        s.coordinator = self
        self.scene = s
        return s
    }

    // MARK: - Actions

    func startLevel(id: Int) {
        currentLevel = id
        bankedCount = 0
        operatorsUsed = 0
        starRating = 0
        attemptNumber = 1
        gamePhase = .preview

        scene?.setupBoard()
    }

    func undoLastOperator() {
        // Will be implemented in M4
    }

    func pauseGame() {
        gamePhase = .paused
    }

    func resumeGame() {
        gamePhase = .playing
    }
}
