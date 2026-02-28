import Foundation

/// Orchestrates ad provider and policy counters.
/// Singleton; wired into overlays via GameplayContainerView.
@MainActor @Observable
final class AdManager {
    static let shared = AdManager()

    private let provider: AdProviding

    // MARK: - State

    /// Whether an interstitial is pending display (set after policy check, consumed after show)
    var interstitialPending = false

    /// Whether a rewarded ad was completed (consumed by caller after Fix It)
    var rewardedCompleted = false

    // MARK: - Placements

    private enum Placement {
        static let interstitialPostWin = "post_win"
        static let interstitialPostFail = "post_fail"
        static let rewardedFixIt = "fix_it"
    }

    // MARK: - Init

    private init() {
        self.provider = StubAdProvider()
    }

    /// For testing with a custom provider
    init(provider: AdProviding) {
        self.provider = provider
    }

    // MARK: - Preload

    func preloadAds() async {
        await provider.preloadInterstitial(placement: Placement.interstitialPostWin)
        await provider.preloadInterstitial(placement: Placement.interstitialPostFail)
        await provider.preloadRewarded(placement: Placement.rewardedFixIt)
    }

    // MARK: - Post-Win Flow

    /// Check policy and show interstitial after win if warranted.
    /// Returns true if an ad was shown (caller may want to wait).
    func handlePostWin(
        winCount: Int,
        level: Int,
        adsRemoved: Bool
    ) async -> Bool {
        guard AdPolicy.shouldShowInterstitialAfterWin(
            winCount: winCount,
            level: level,
            adsRemoved: adsRemoved
        ) else { return false }

        let shown = await provider.showInterstitial(placement: Placement.interstitialPostWin)
        if shown {
            // Preload next one
            await provider.preloadInterstitial(placement: Placement.interstitialPostWin)
        }
        return shown
    }

    // MARK: - Post-Fail Flow

    /// Check policy and show interstitial after fail if warranted.
    /// Returns true if an ad was shown.
    func handlePostFail(
        failCount: Int,
        level: Int,
        adsRemoved: Bool,
        fixItShown: Bool
    ) async -> Bool {
        guard AdPolicy.shouldShowInterstitialAfterFail(
            failCount: failCount,
            level: level,
            adsRemoved: adsRemoved,
            fixItShown: fixItShown
        ) else { return false }

        let shown = await provider.showInterstitial(placement: Placement.interstitialPostFail)
        if shown {
            await provider.preloadInterstitial(placement: Placement.interstitialPostFail)
        }
        return shown
    }

    // MARK: - Rewarded Fix It

    /// Show rewarded ad for Fix It. Returns true if user earned the reward.
    func showRewardedForFixIt() async -> Bool {
        let earned = await provider.showRewarded(placement: Placement.rewardedFixIt)
        if earned {
            await provider.preloadRewarded(placement: Placement.rewardedFixIt)
        }
        return earned
    }
}
