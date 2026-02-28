import Foundation

/// All locked game constants. Single source of truth.
enum GameConstants {
    // MARK: - Board
    static let laneCount = 4
    static let rowCount = 12
    static let slotsPerRow = 3 // Boundary slots A/B/C

    // MARK: - Shuriken
    static let shurikenPerLevel = 24
    static let wavesPerLevel = 6
    static let shurikenPerWave = 4
    static let shurikenRowTravelTime: Double = 0.33 // seconds per row (4.0s total)

    // MARK: - Spawn Pacing
    static let interShurikenSpacing: Double = 0.6 // seconds between shuriken in a wave
    static let breathWindowDuration: Double = 1.2 // seconds between waves
    static let spawnPreviewCount = 8 // NEXT 8

    // MARK: - Operators
    static let activeOperatorCap = 3
    static let chargesPerOperator = 3

    // MARK: - Gates
    static let defaultToggleCycleEveryNSpawns = 2
    static let jamThreshold = 3 // jams in one lane => overflow fail

    // MARK: - Preview Phase
    static let previewBannerDuration: Double = 0.5
    static let previewBoardDuration: Double = 1.5
    static var totalPreviewDuration: Double { previewBannerDuration + previewBoardDuration }

    // MARK: - Stars (par)
    static let threeStarMaxOperators = 6
    static let twoStarMaxOperators = 8

    // MARK: - Economy
    static let baseCoinsPerWin = 10
    static let coinsPerStar = 5
    static let baseXPPerWin = 100
    static let xpPerStar = 50

    // MARK: - Belt Thresholds
    static let beltThresholds: [(name: String, xp: Int)] = [
        ("White", 0), ("Yellow", 500), ("Orange", 1500),
        ("Green", 3000), ("Blue", 5000), ("Purple", 8000),
        ("Black", 12000), ("Red", 17000)
    ]

    // MARK: - Milestone Tokens
    static let levelsPerMilestoneToken = 10
    static let tokensPerBeltRankUp = 2

    // MARK: - Fix It
    static let fixItMaxPerAttempt = 1
    static let fixItMaxPerSession = 3
    static let fixItFreeUntilLevel = 10

    // MARK: - Ads
    static let interstitialWinFrequency = 3
    static let interstitialFailFrequency = 2
    static let adsStartAfterLevel = 10

    // MARK: - Campaign
    static let totalCampaignLevels = 100
}
