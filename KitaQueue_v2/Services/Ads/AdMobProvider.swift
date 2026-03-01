import Foundation

// MARK: - AdMob Provider (Real Implementation)
//
// To activate real AdMob ads:
// 1. Add GoogleMobileAds SPM package to project.yml:
//    packages:
//      GoogleMobileAds:
//        url: https://github.com/googleads/swift-package-manager-google-mobile-ads
//        from: "11.0.0"
// 2. Change AdManager.init() to use AdMobProvider() instead of StubAdProvider()
// 3. Replace test ad unit IDs below with production IDs
// 4. Uncomment the implementation below
//
// Test Ad Unit IDs (Google-provided):
// - Interstitial: ca-app-pub-3940256099942544/4411468910
// - Rewarded: ca-app-pub-3940256099942544/1712485313

/*
import GoogleMobileAds
import UIKit

@MainActor
final class AdMobProvider: AdProviding {

    private var interstitialAds: [String: GADInterstitialAd] = [:]
    private var rewardedAds: [String: GADRewardedAd] = [:]

    private let interstitialUnitId = "ca-app-pub-3940256099942544/4411468910" // Test ID
    private let rewardedUnitId = "ca-app-pub-3940256099942544/1712485313"     // Test ID

    func preloadInterstitial(placement: String) async {
        do {
            let ad = try await GADInterstitialAd.load(
                withAdUnitID: interstitialUnitId,
                request: GADRequest()
            )
            interstitialAds[placement] = ad
        } catch {
            // Failed to load — will try again on next opportunity
        }
    }

    func showInterstitial(placement: String) async -> Bool {
        guard let ad = interstitialAds.removeValue(forKey: placement) else { return false }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController
        else { return false }

        ad.present(fromRootViewController: rootVC)
        return true
    }

    func preloadRewarded(placement: String) async {
        do {
            let ad = try await GADRewardedAd.load(
                withAdUnitID: rewardedUnitId,
                request: GADRequest()
            )
            rewardedAds[placement] = ad
        } catch {
            // Failed to load
        }
    }

    func showRewarded(placement: String) async -> Bool {
        guard let ad = rewardedAds.removeValue(forKey: placement) else { return false }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController
        else { return false }

        return await withCheckedContinuation { continuation in
            ad.present(fromRootViewController: rootVC) {
                continuation.resume(returning: true)
            }
        }
    }
}
*/
