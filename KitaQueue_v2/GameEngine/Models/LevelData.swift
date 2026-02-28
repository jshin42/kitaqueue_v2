import Foundation

struct LevelData: Codable, Sendable {
    let id: Int
    let waves: [[WaveEntry]]  // 6 waves of 4 entries each
    let gates: [Gate]
    let threeStarMaxOps: Int
    let twoStarMaxOps: Int

    /// Tutorial overlay config (nil for non-FTUE levels)
    var tutorialConfig: TutorialConfig?

    struct WaveEntry: Codable, Sendable {
        let lane: Int            // 0-3
        let color: ShurikenColor
    }

    struct TutorialConfig: Codable, Sendable {
        let overlayText: String
        let endCardText: String
        let pauseBeforeFirstSpawn: Bool
    }

    /// Total shuriken count
    var totalShuriken: Int {
        waves.reduce(0) { $0 + $1.count }
    }
}
