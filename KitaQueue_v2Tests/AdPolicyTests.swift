import Testing
@testable import KitaQueue_v2

@Suite("Ad Policy Tests")
struct AdPolicyTests {

    // MARK: - Interstitial After Win

    @Test("No interstitial when ads removed")
    func noInterstitialAdsRemoved() {
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 3, level: 15, adsRemoved: true))
    }

    @Test("No interstitial during FTUE (level <= 10)")
    func noInterstitialFTUE() {
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 3, level: 10, adsRemoved: false))
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 6, level: 5, adsRemoved: false))
    }

    @Test("Interstitial every 3 wins after level 10")
    func interstitialWinFrequency() {
        // Win 1, 2 = no
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 1, level: 11, adsRemoved: false))
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 2, level: 11, adsRemoved: false))
        // Win 3 = yes
        #expect(AdPolicy.shouldShowInterstitialAfterWin(winCount: 3, level: 11, adsRemoved: false))
        // Win 4, 5 = no
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 4, level: 15, adsRemoved: false))
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 5, level: 15, adsRemoved: false))
        // Win 6 = yes
        #expect(AdPolicy.shouldShowInterstitialAfterWin(winCount: 6, level: 15, adsRemoved: false))
        // Win 9 = yes
        #expect(AdPolicy.shouldShowInterstitialAfterWin(winCount: 9, level: 20, adsRemoved: false))
    }

    @Test("No interstitial at win count 0")
    func noInterstitialZeroWins() {
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 0, level: 15, adsRemoved: false))
    }

    // MARK: - Interstitial After Fail

    @Test("No interstitial after fail when ads removed")
    func noFailInterstitialAdsRemoved() {
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 15, adsRemoved: true, fixItShown: false))
    }

    @Test("No interstitial after fail during FTUE")
    func noFailInterstitialFTUE() {
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 8, adsRemoved: false, fixItShown: false))
    }

    @Test("No interstitial after fail when Fix It shown")
    func noFailInterstitialFixItShown() {
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 15, adsRemoved: false, fixItShown: true))
    }

    @Test("Interstitial every 2 fails after level 10")
    func interstitialFailFrequency() {
        // Fail 1 = no
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 1, level: 11, adsRemoved: false, fixItShown: false))
        // Fail 2 = yes
        #expect(AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 11, adsRemoved: false, fixItShown: false))
        // Fail 3 = no
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 3, level: 15, adsRemoved: false, fixItShown: false))
        // Fail 4 = yes
        #expect(AdPolicy.shouldShowInterstitialAfterFail(failCount: 4, level: 15, adsRemoved: false, fixItShown: false))
    }

    @Test("No interstitial at fail count 0")
    func noInterstitialZeroFails() {
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 0, level: 15, adsRemoved: false, fixItShown: false))
    }

    // MARK: - Fix It Requires Ad

    @Test("Fix It is free during FTUE")
    func fixItFreeFTUE() {
        #expect(!AdPolicy.fixItRequiresAd(level: 1))
        #expect(!AdPolicy.fixItRequiresAd(level: 5))
        #expect(!AdPolicy.fixItRequiresAd(level: 10))
    }

    @Test("Fix It requires ad after FTUE")
    func fixItRequiresAdPostFTUE() {
        #expect(AdPolicy.fixItRequiresAd(level: 11))
        #expect(AdPolicy.fixItRequiresAd(level: 25))
        #expect(AdPolicy.fixItRequiresAd(level: 100))
    }

    // MARK: - Fix It Offer Logic

    @Test("Overflow always qualifies for Fix It")
    func overflowAlwaysQualifies() {
        #expect(AdPolicy.shouldOfferFixIt(
            reason: .overflow(lane: 1),
            remainingToBank: 20,
            overflowMargin: 0,
            usedThisAttempt: 0,
            usedThisSession: 0
        ))
    }

    @Test("Misbank qualifies when remaining <= 3")
    func misbankQualifiesNearCompletion() {
        #expect(AdPolicy.shouldOfferFixIt(
            reason: .misbank(shurikenColor: .red, bankLane: 1),
            remainingToBank: 3,
            overflowMargin: nil,
            usedThisAttempt: 0,
            usedThisSession: 0
        ))
        #expect(AdPolicy.shouldOfferFixIt(
            reason: .misbank(shurikenColor: .red, bankLane: 1),
            remainingToBank: 1,
            overflowMargin: nil,
            usedThisAttempt: 0,
            usedThisSession: 0
        ))
    }

    @Test("Misbank does not qualify when remaining > 3")
    func misbankDoesNotQualifyFarFromComplete() {
        #expect(!AdPolicy.shouldOfferFixIt(
            reason: .misbank(shurikenColor: .red, bankLane: 1),
            remainingToBank: 4,
            overflowMargin: nil,
            usedThisAttempt: 0,
            usedThisSession: 0
        ))
        #expect(!AdPolicy.shouldOfferFixIt(
            reason: .misbank(shurikenColor: .red, bankLane: 1),
            remainingToBank: 20,
            overflowMargin: nil,
            usedThisAttempt: 0,
            usedThisSession: 0
        ))
    }

    @Test("Fix It capped at 1 per attempt")
    func fixItCapPerAttempt() {
        #expect(!AdPolicy.shouldOfferFixIt(
            reason: .overflow(lane: 0),
            remainingToBank: 1,
            overflowMargin: 0,
            usedThisAttempt: 1,
            usedThisSession: 0
        ))
    }

    @Test("Fix It capped at 3 per session")
    func fixItCapPerSession() {
        #expect(!AdPolicy.shouldOfferFixIt(
            reason: .overflow(lane: 0),
            remainingToBank: 1,
            overflowMargin: 0,
            usedThisAttempt: 0,
            usedThisSession: 3
        ))
    }

    @Test("Fix It allowed at session count 2")
    func fixItAllowedBeforeSessionCap() {
        #expect(AdPolicy.shouldOfferFixIt(
            reason: .overflow(lane: 0),
            remainingToBank: 10,
            overflowMargin: 0,
            usedThisAttempt: 0,
            usedThisSession: 2
        ))
    }

    // MARK: - Combined Scenarios

    @Test("Full session scenario: ads removed blocks everything")
    func fullSessionAdsRemoved() {
        // Win 3 at level 15 with ads removed = no interstitial
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 3, level: 15, adsRemoved: true))
        // Fail 2 at level 15 with ads removed = no interstitial
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 15, adsRemoved: true, fixItShown: false))
        // Fix It still requires ad gating (remove ads only removes interstitials)
        #expect(AdPolicy.fixItRequiresAd(level: 15))
    }

    @Test("Fix It suppresses post-fail interstitial")
    func fixItSuppressesInterstitial() {
        // Fail 2 at level 15 would normally trigger interstitial
        #expect(AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 15, adsRemoved: false, fixItShown: false))
        // But not when Fix It was shown
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 15, adsRemoved: false, fixItShown: true))
    }

    @Test("Level boundary: level 10 vs 11")
    func levelBoundary() {
        // Level 10 = FTUE, no ads
        #expect(!AdPolicy.shouldShowInterstitialAfterWin(winCount: 3, level: 10, adsRemoved: false))
        #expect(!AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 10, adsRemoved: false, fixItShown: false))
        #expect(!AdPolicy.fixItRequiresAd(level: 10))

        // Level 11 = post-FTUE, ads enabled
        #expect(AdPolicy.shouldShowInterstitialAfterWin(winCount: 3, level: 11, adsRemoved: false))
        #expect(AdPolicy.shouldShowInterstitialAfterFail(failCount: 2, level: 11, adsRemoved: false, fixItShown: false))
        #expect(AdPolicy.fixItRequiresAd(level: 11))
    }
}
