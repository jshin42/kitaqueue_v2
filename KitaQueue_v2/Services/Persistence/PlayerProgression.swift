import Foundation

struct PlayerProgression: Codable, Equatable {
    var currentLevel: Int = 1
    var bestStars: [Int: Int] = [:] // levelId -> best stars (1-3)
    var totalCoins: Int = 0
    var totalTokens: Int = 0
    var totalXP: Int = 0
    var completedLevels: Int = 0

    var beltRank: BeltRank {
        BeltRank.rank(for: totalXP)
    }
}

enum BeltRank: Int, Codable, CaseIterable, Comparable {
    case white = 0, yellow, orange, green, blue, purple, black, red

    var displayName: String {
        switch self {
        case .white: "White"
        case .yellow: "Yellow"
        case .orange: "Orange"
        case .green: "Green"
        case .blue: "Blue"
        case .purple: "Purple"
        case .black: "Black"
        case .red: "Red"
        }
    }

    var xpThreshold: Int {
        switch self {
        case .white: 0
        case .yellow: 500
        case .orange: 1500
        case .green: 3000
        case .blue: 5000
        case .purple: 8000
        case .black: 12000
        case .red: 17000
        }
    }

    static func rank(for xp: Int) -> BeltRank {
        for rank in BeltRank.allCases.reversed() {
            if xp >= rank.xpThreshold { return rank }
        }
        return .white
    }

    static func < (lhs: BeltRank, rhs: BeltRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
