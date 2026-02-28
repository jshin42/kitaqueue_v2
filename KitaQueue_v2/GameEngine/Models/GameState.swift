import Foundation

struct GameState: Hashable, Sendable {
    enum GamePhase: Hashable, Sendable {
        case preview, playing, tutorialPaused, paused, won, failed
    }

    var phase: GamePhase = .preview
    var elapsedTime: Double = 0
    var timestep: Int = 0

    // Shuriken
    var shuriken: [Shuriken] = []
    var spawnedCount: Int = 0
    var globalSpawnIndex: Int = 0

    // Banking
    var bankedCount: Int = 0

    // Operators
    var operators: [Operator] = []
    var totalOperatorsPlaced: Int = 0
    var nextOperatorId: Int = 0

    // Jams
    var jamCounts: [Int: Int] = [:] // lane -> jam count

    // Fail
    var failReason: FailReason? = nil

    // Near-miss info
    var overflowMargin: Int? = nil // how many jams away from threshold when failed

    // Preview timer
    var previewElapsed: Double = 0

    // Wave tracking
    var currentWave: Int = 0
    var shurikenInCurrentWave: Int = 0
    var timeSinceLastSpawn: Double = 0
    var waveBreathing: Bool = false
    var breathElapsed: Double = 0
}
