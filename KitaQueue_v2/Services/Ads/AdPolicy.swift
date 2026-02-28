import Foundation

/// Pure logic for ad display decisions. Fully testable, no side effects.
enum AdPolicy {

    // MARK: - Interstitial (post-win)

    /// Whether to show an interstitial after a win.
    /// - Parameters:
    ///   - winCount: Total wins this session (1-based, incremented before calling)
    ///   - level: Level that was just won
    ///   - adsRemoved: Whether user purchased Remove Ads
    static func shouldShowInterstitialAfterWin(
        winCount: Int,
        level: Int,
        adsRemoved: Bool
    ) -> Bool {
        guard !adsRemoved else { return false }
        guard level > GameConstants.adsStartAfterLevel else { return false }
        return winCount > 0 && winCount % GameConstants.interstitialWinFrequency == 0
    }

    // MARK: - Interstitial (post-fail)

    /// Whether to show an interstitial after a fail.
    /// - Parameters:
    ///   - failCount: Total fails this session (1-based, incremented before calling)
    ///   - level: Level that was just failed
    ///   - adsRemoved: Whether user purchased Remove Ads
    ///   - fixItShown: Whether Fix It was shown on this fail (suppresses interstitial)
    static func shouldShowInterstitialAfterFail(
        failCount: Int,
        level: Int,
        adsRemoved: Bool,
        fixItShown: Bool
    ) -> Bool {
        guard !adsRemoved else { return false }
        guard level > GameConstants.adsStartAfterLevel else { return false }
        guard !fixItShown else { return false }
        return failCount > 0 && failCount % GameConstants.interstitialFailFrequency == 0
    }

    // MARK: - Fix It (rewarded ad gating)

    /// Whether Fix It requires a rewarded ad (vs. being free).
    /// Free during FTUE (level <= fixItFreeUntilLevel); rewarded after.
    static func fixItRequiresAd(level: Int) -> Bool {
        level > GameConstants.fixItFreeUntilLevel
    }

    /// Whether to offer Fix It on this fail.
    /// - Parameters:
    ///   - reason: Why the player failed
    ///   - remainingToBank: Shuriken remaining to bank (totalShuriken - bankedCount)
    ///   - overflowMargin: How close to overflow threshold (nil if not overflow)
    ///   - usedThisAttempt: Fix Its used this attempt (max 1)
    ///   - usedThisSession: Fix Its used this session (max 3)
    static func shouldOfferFixIt(
        reason: FailReason,
        remainingToBank: Int,
        overflowMargin: Int?,
        usedThisAttempt: Int,
        usedThisSession: Int
    ) -> Bool {
        guard usedThisAttempt < GameConstants.fixItMaxPerAttempt else { return false }
        guard usedThisSession < GameConstants.fixItMaxPerSession else { return false }

        switch reason {
        case .overflow:
            // Overflow always qualifies (the margin was 0 at fail, meaning 1 before)
            return true
        case .misbank:
            return remainingToBank <= 3
        }
    }
}
