import Foundation

/// DEBUG stub that simulates ad presentation with a brief delay.
/// Replaced by real AdMob provider in M15.
@MainActor
final class StubAdProvider: AdProviding {
    private var preloadedInterstitials: Set<String> = []
    private var preloadedRewarded: Set<String> = []

    func preloadInterstitial(placement: String) async {
        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(200))
        preloadedInterstitials.insert(placement)
    }

    func showInterstitial(placement: String) async -> Bool {
        guard preloadedInterstitials.remove(placement) != nil else { return false }
        // Simulate ad display
        try? await Task.sleep(for: .milliseconds(500))
        return true
    }

    func preloadRewarded(placement: String) async {
        try? await Task.sleep(for: .milliseconds(200))
        preloadedRewarded.insert(placement)
    }

    func showRewarded(placement: String) async -> Bool {
        guard preloadedRewarded.remove(placement) != nil else { return false }
        // Simulate rewarded ad — user always "watches" in stub
        try? await Task.sleep(for: .milliseconds(500))
        return true
    }
}
