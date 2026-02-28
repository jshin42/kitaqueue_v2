import Foundation

enum StarCalculator {
    /// Calculate stars based on operators used
    static func stars(operatorsUsed: Int, threeStarMax: Int, twoStarMax: Int) -> Int {
        if operatorsUsed <= threeStarMax { return 3 }
        if operatorsUsed <= twoStarMax { return 2 }
        return 1
    }

    /// Calculate stars using default thresholds
    static func stars(operatorsUsed: Int) -> Int {
        stars(
            operatorsUsed: operatorsUsed,
            threeStarMax: GameConstants.threeStarMaxOperators,
            twoStarMax: GameConstants.twoStarMaxOperators
        )
    }

    /// Calculate coins earned
    static func coins(stars: Int) -> Int {
        GameConstants.baseCoinsPerWin + GameConstants.coinsPerStar * stars
    }

    /// Calculate XP earned
    static func xp(stars: Int) -> Int {
        GameConstants.baseXPPerWin + GameConstants.xpPerStar * stars
    }

    /// "Missed 3-star by X" message, or nil if already 3-star
    static func missedThreeStarBy(operatorsUsed: Int, threeStarMax: Int) -> Int? {
        let diff = operatorsUsed - threeStarMax
        return diff > 0 ? diff : nil
    }
}
