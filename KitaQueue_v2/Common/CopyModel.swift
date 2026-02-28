import Foundation

/// Single source of truth for all player-facing strings.
enum CopyModel {
    // MARK: - Tutorial Overlays (L1-L5)
    static let tutorialOverlays: [Int: String] = [
        1: "Match color to bank.",
        2: "Swipe to place a slash.",
        3: "Each slash handles 3 shuriken, then fades.",
        4: "Paint gates change shuriken color.",
        5: "3 jams in one lane = overflow!"
    ]

    // MARK: - Tutorial End Cards (L1-L5)
    static let tutorialEndCards: [Int: String] = [
        1: "Slashes reroute. Banking is the goal.",
        2: "Slashes deflect shuriken between lanes.",
        3: "Plan your slashes carefully.",
        4: "Color can change before banking.",
        5: "Keep lanes clear to survive."
    ]

    // MARK: - Win/Fail
    static let clearBanner = "CLEAR!"
    static let failBannerOverflow = "Overflow"
    static let failBannerMisbank = "Misbank"

    static func missedThreeStarMessage(by count: Int) -> String {
        "Missed 3\u{2605} by \(count) operator\(count == 1 ? "" : "s")"
    }

    static func bankedMessage(banked: Int, total: Int) -> String {
        "Banked \(banked)/\(total)"
    }

    static let overflowNearMiss = "1 jam too many!"

    static func misbankNearMiss(remaining: Int) -> String {
        "Only \(remaining) more to bank!"
    }

    static func attemptMessage(attempt: Int) -> String {
        "Attempt #\(attempt) — keep going!"
    }

    // MARK: - Fix It
    static let fixItOverflow = "Clear 1 Jam"
    static let fixItMisbank = "Undo Last Slash"

    // MARK: - Pre-Boost
    static let preboostSlash = "+1 Slash Capacity"
    static let preboostUndo = "+1 Free Undo"

    // MARK: - HUD
    static let nextLabel = "NEXT"
    static let playNext = "PLAY NEXT"
    static let retry = "Retry"
    static let fixIt = "Fix It"
    static let next = "Next"
    static let home = "Home"
    static let resume = "Resume"
    static let restart = "Restart"
    static let quit = "Quit"
}
