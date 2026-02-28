import Foundation

/// Protocol for ad providers. Real AdMob implementation added in M15;
/// DEBUG builds use StubAdProvider.
@MainActor
protocol AdProviding: AnyObject {
    /// Preload an interstitial ad for the given placement.
    func preloadInterstitial(placement: String) async

    /// Show a preloaded interstitial. Returns true if shown.
    func showInterstitial(placement: String) async -> Bool

    /// Preload a rewarded ad for the given placement.
    func preloadRewarded(placement: String) async

    /// Show a rewarded ad. Returns true if the user earned the reward.
    func showRewarded(placement: String) async -> Bool
}
