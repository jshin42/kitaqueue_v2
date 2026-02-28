import Testing
import Foundation
@testable import KitaQueue_v2

@Suite("Telemetry Tests")
struct TelemetryTests {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    // MARK: - Event Name Mapping

    @Test("All 31 events have correct event names")
    func eventNames() {
        let events: [(TelemetryEvent, String)] = [
            (.appOpen, "app_open"),
            (.hubViewed, "hub_viewed"),
            (.playNextClicked, "play_next_clicked"),
            (.dailyPackStarted, "daily_pack_started"),
            (.dailyPackCompleted, "daily_pack_completed"),
            (.streakUpdated(newStreak: 5), "streak_updated"),
            (.questCompleted(questId: "bank_30"), "quest_completed"),
            (.levelStart(levelId: 1, attemptId: 1), "level_start"),
            (.operatorPreviewed(row: 4, slot: "A"), "operator_previewed"),
            (.operatorPlaced(row: 4, slot: "A", charges: 3, activeCount: 1), "operator_placed"),
            (.operatorTriggered(row: 4, slot: "A", shurikenId: 1, remainingCharges: 2), "operator_triggered"),
            (.gateTriggered(type: "color", lane: 1, row: 6, result: "jam"), "gate_triggered"),
            (.shurikenBanked(shurikenId: 1, bankColor: "red"), "shuriken_banked"),
            (.levelWin(levelId: 1, usedOperators: 3, stars: 3), "level_win"),
            (.levelFail(levelId: 5, reason: "overflow", remainingToBank: 8, overflowMargin: 0, usedOperators: 0), "level_fail"),
            (.fixitOfferShown(reason: "overflow"), "fixit_offer_shown"),
            (.fixitOfferAccepted(type: "rewarded"), "fixit_offer_accepted"),
            (.adImpression(format: "interstitial", placement: "post_win"), "ad_impression"),
            (.purchase(sku: "com.kitaqueue.remove_ads"), "purchase"),
            (.removeAdsEnabled(enabled: true), "remove_ads_enabled"),
            (.tutorialStepShown(stepId: "L1_overlay", levelId: 1), "tutorial_step_shown"),
            (.tutorialStepCompleted(stepId: "L1_overlay", levelId: 1, durationMs: 2500), "tutorial_step_completed"),
            (.preboostOfferShown(type: "slash", trigger: "first_try_win"), "preboost_offer_shown"),
            (.preboostOfferAccepted(type: "slash", choice: "slash_capacity"), "preboost_offer_accepted"),
            (.nearMissDetected(type: "overflow", proximityMetric: 1, levelId: 5), "near_miss_detected"),
            (.currencyFlow(source: "level_win", sink: "coins", amount: 25, context: "L10_3star"), "currency_flow"),
            (.feedbackEvent(type: "bank_tick", latencyMs: 16), "feedback_event"),
            (.goalSalienceShown(proximityToWin: 4, bankedCount: 20), "goal_salience_shown"),
            (.causalityTrace(failReason: "overflow", eventChain: "jam→jam→jam"), "causality_trace"),
            (.momentumWindowClosed(accepted: true, timeOpenMs: 3000), "momentum_window_closed"),
            (.attemptCountDisplayed(attempts: 3, coinsEarned: 45), "attempt_count_displayed"),
        ]

        #expect(events.count == 31, "Should have exactly 31 event types")

        for (event, expectedName) in events {
            #expect(event.eventName == expectedName, "Event name mismatch for \(expectedName)")
        }
    }

    // MARK: - Encoding

    @Test("Events encode to valid JSON")
    func encodesToJSON() throws {
        let event = TelemetryEvent.levelWin(levelId: 5, usedOperators: 4, stars: 3)
        let data = try encoder.encode(event)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"event\":\"level_win\""))
        #expect(json.contains("\"levelId\":5"))
        #expect(json.contains("\"usedOperators\":4"))
        #expect(json.contains("\"stars\":3"))
    }

    @Test("Level fail encodes overflow margin as optional")
    func levelFailEncoding() throws {
        // With overflow margin
        let withMargin = TelemetryEvent.levelFail(
            levelId: 5, reason: "overflow", remainingToBank: 8,
            overflowMargin: 0, usedOperators: 2
        )
        let data1 = try encoder.encode(withMargin)
        let json1 = String(data: data1, encoding: .utf8)!
        #expect(json1.contains("\"overflowMargin\":0"))

        // Without overflow margin (misbank)
        let noMargin = TelemetryEvent.levelFail(
            levelId: 5, reason: "misbank", remainingToBank: 2,
            overflowMargin: nil, usedOperators: 3
        )
        let data2 = try encoder.encode(noMargin)
        let json2 = String(data: data2, encoding: .utf8)!
        #expect(!json2.contains("overflowMargin"))
    }

    @Test("Simple events encode without extra fields")
    func simpleEventEncoding() throws {
        let event = TelemetryEvent.appOpen
        let data = try encoder.encode(event)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "{\"event\":\"app_open\"}")
    }

    @Test("Streak event includes new streak value")
    func streakEncoding() throws {
        let event = TelemetryEvent.streakUpdated(newStreak: 7)
        let data = try encoder.encode(event)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"newStreak\":7"))
    }

    @Test("Currency flow event includes all fields")
    func currencyFlowEncoding() throws {
        let event = TelemetryEvent.currencyFlow(
            source: "level_win", sink: "coins", amount: 25, context: "L10_3star"
        )
        let data = try encoder.encode(event)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"source\":\"level_win\""))
        #expect(json.contains("\"sink\":\"coins\""))
        #expect(json.contains("\"amount\":25"))
        #expect(json.contains("\"context\":\"L10_3star\""))
    }

    @Test("Gate triggered event includes all fields")
    func gateTriggeredEncoding() throws {
        let event = TelemetryEvent.gateTriggered(type: "toggle", lane: 2, row: 8, result: "pass")
        let data = try encoder.encode(event)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"type\":\"toggle\""))
        #expect(json.contains("\"lane\":2"))
        #expect(json.contains("\"row\":8"))
        #expect(json.contains("\"result\":\"pass\""))
    }

    @Test("Operator placed event includes charges and active count")
    func operatorPlacedEncoding() throws {
        let event = TelemetryEvent.operatorPlaced(row: 6, slot: "B", charges: 3, activeCount: 2)
        let data = try encoder.encode(event)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"charges\":3"))
        #expect(json.contains("\"activeCount\":2"))
    }

    // MARK: - Telemetry Service

    @Test("TelemetryService singleton exists")
    func singletonExists() {
        let service = TelemetryService.shared
        #expect(service === TelemetryService.shared)
    }

    @Test("Logging does not crash for any event type")
    func logAllEvents() {
        let service = TelemetryService.shared
        service.setLevel(1, attempt: 1)

        // Log all 31 event types — should not crash
        service.log(.appOpen)
        service.log(.hubViewed)
        service.log(.playNextClicked)
        service.log(.dailyPackStarted)
        service.log(.dailyPackCompleted)
        service.log(.streakUpdated(newStreak: 3))
        service.log(.questCompleted(questId: "bank_30"))
        service.log(.levelStart(levelId: 1, attemptId: 1))
        service.log(.operatorPreviewed(row: 4, slot: "A"))
        service.log(.operatorPlaced(row: 4, slot: "A", charges: 3, activeCount: 1))
        service.log(.operatorTriggered(row: 4, slot: "A", shurikenId: 0, remainingCharges: 2))
        service.log(.gateTriggered(type: "color", lane: 1, row: 6, result: "jam"))
        service.log(.shurikenBanked(shurikenId: 0, bankColor: "red"))
        service.log(.levelWin(levelId: 1, usedOperators: 3, stars: 3))
        service.log(.levelFail(levelId: 5, reason: "overflow", remainingToBank: 8, overflowMargin: 0, usedOperators: 0))
        service.log(.fixitOfferShown(reason: "overflow"))
        service.log(.fixitOfferAccepted(type: "rewarded"))
        service.log(.adImpression(format: "interstitial", placement: "post_win"))
        service.log(.purchase(sku: "com.kitaqueue.remove_ads"))
        service.log(.removeAdsEnabled(enabled: true))
        service.log(.tutorialStepShown(stepId: "L1_overlay", levelId: 1))
        service.log(.tutorialStepCompleted(stepId: "L1_overlay", levelId: 1, durationMs: 2500))
        service.log(.preboostOfferShown(type: "slash", trigger: "first_try_win"))
        service.log(.preboostOfferAccepted(type: "slash", choice: "slash_capacity"))
        service.log(.nearMissDetected(type: "overflow", proximityMetric: 1, levelId: 5))
        service.log(.currencyFlow(source: "level_win", sink: "coins", amount: 25, context: "L10"))
        service.log(.feedbackEvent(type: "bank_tick", latencyMs: 16))
        service.log(.goalSalienceShown(proximityToWin: 4, bankedCount: 20))
        service.log(.causalityTrace(failReason: "overflow", eventChain: "jam→jam→jam"))
        service.log(.momentumWindowClosed(accepted: true, timeOpenMs: 3000))
        service.log(.attemptCountDisplayed(attempts: 3, coinsEarned: 45))
    }
}
