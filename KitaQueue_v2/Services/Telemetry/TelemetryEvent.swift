import Foundation

/// All 31 telemetry events (20 spec + 11 guiding principles).
/// Each event carries its specific payload as associated values.
enum TelemetryEvent: Encodable {

    // MARK: - Spec Events (1-20)

    /// 1. App launched
    case appOpen

    /// 2. Hub/Home tab viewed
    case hubViewed

    /// 3. Play Next button tapped
    case playNextClicked

    /// 4. Daily pack started
    case dailyPackStarted

    /// 5. Daily pack completed
    case dailyPackCompleted

    /// 6. Streak updated
    case streakUpdated(newStreak: Int)

    /// 7. Quest completed
    case questCompleted(questId: String)

    /// 8. Level started
    case levelStart(levelId: Int, attemptId: Int)

    /// 9. Operator ghost preview shown
    case operatorPreviewed(row: Int, slot: String)

    /// 10. Operator placed
    case operatorPlaced(row: Int, slot: String, charges: Int, activeCount: Int)

    /// 11. Operator triggered by shuriken
    case operatorTriggered(row: Int, slot: String, shurikenId: Int, remainingCharges: Int)

    /// 12. Gate triggered
    case gateTriggered(type: String, lane: Int, row: Int, result: String)

    /// 13. Shuriken banked
    case shurikenBanked(shurikenId: Int, bankColor: String)

    /// 14. Level won
    case levelWin(levelId: Int, usedOperators: Int, stars: Int)

    /// 15. Level failed
    case levelFail(levelId: Int, reason: String, remainingToBank: Int, overflowMargin: Int?, usedOperators: Int)

    /// 16. Fix It offer shown
    case fixitOfferShown(reason: String)

    /// 17. Fix It offer accepted
    case fixitOfferAccepted(type: String)

    /// 18. Ad impression
    case adImpression(format: String, placement: String)

    /// 19. Purchase completed
    case purchase(sku: String)

    /// 20. Remove ads toggled
    case removeAdsEnabled(enabled: Bool)

    // MARK: - Guiding Principles Events (21-31)

    /// 21. Tutorial step shown
    case tutorialStepShown(stepId: String, levelId: Int)

    /// 22. Tutorial step completed
    case tutorialStepCompleted(stepId: String, levelId: Int, durationMs: Int)

    /// 23. Pre-boost offer shown
    case preboostOfferShown(type: String, trigger: String)

    /// 24. Pre-boost offer accepted
    case preboostOfferAccepted(type: String, choice: String)

    /// 25. Near-miss detected
    case nearMissDetected(type: String, proximityMetric: Int, levelId: Int)

    /// 26. Currency flow
    case currencyFlow(source: String, sink: String, amount: Int, context: String)

    /// 27. Feedback event (micro-reward timing)
    case feedbackEvent(type: String, latencyMs: Int)

    /// 28. Goal salience shown
    case goalSalienceShown(proximityToWin: Int, bankedCount: Int)

    /// 29. Causality trace (why they failed)
    case causalityTrace(failReason: String, eventChain: String)

    /// 30. Momentum window closed
    case momentumWindowClosed(accepted: Bool, timeOpenMs: Int)

    /// 31. Attempt count displayed
    case attemptCountDisplayed(attempts: Int, coinsEarned: Int)

    // MARK: - Encodable

    var eventName: String {
        switch self {
        case .appOpen: "app_open"
        case .hubViewed: "hub_viewed"
        case .playNextClicked: "play_next_clicked"
        case .dailyPackStarted: "daily_pack_started"
        case .dailyPackCompleted: "daily_pack_completed"
        case .streakUpdated: "streak_updated"
        case .questCompleted: "quest_completed"
        case .levelStart: "level_start"
        case .operatorPreviewed: "operator_previewed"
        case .operatorPlaced: "operator_placed"
        case .operatorTriggered: "operator_triggered"
        case .gateTriggered: "gate_triggered"
        case .shurikenBanked: "shuriken_banked"
        case .levelWin: "level_win"
        case .levelFail: "level_fail"
        case .fixitOfferShown: "fixit_offer_shown"
        case .fixitOfferAccepted: "fixit_offer_accepted"
        case .adImpression: "ad_impression"
        case .purchase: "purchase"
        case .removeAdsEnabled: "remove_ads_enabled"
        case .tutorialStepShown: "tutorial_step_shown"
        case .tutorialStepCompleted: "tutorial_step_completed"
        case .preboostOfferShown: "preboost_offer_shown"
        case .preboostOfferAccepted: "preboost_offer_accepted"
        case .nearMissDetected: "near_miss_detected"
        case .currencyFlow: "currency_flow"
        case .feedbackEvent: "feedback_event"
        case .goalSalienceShown: "goal_salience_shown"
        case .causalityTrace: "causality_trace"
        case .momentumWindowClosed: "momentum_window_closed"
        case .attemptCountDisplayed: "attempt_count_displayed"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventName, forKey: .event)

        switch self {
        case .appOpen, .hubViewed, .playNextClicked, .dailyPackStarted, .dailyPackCompleted:
            break
        case .streakUpdated(let newStreak):
            try container.encode(newStreak, forKey: .newStreak)
        case .questCompleted(let questId):
            try container.encode(questId, forKey: .questId)
        case .levelStart(let levelId, let attemptId):
            try container.encode(levelId, forKey: .levelId)
            try container.encode(attemptId, forKey: .attemptId)
        case .operatorPreviewed(let row, let slot):
            try container.encode(row, forKey: .row)
            try container.encode(slot, forKey: .slot)
        case .operatorPlaced(let row, let slot, let charges, let activeCount):
            try container.encode(row, forKey: .row)
            try container.encode(slot, forKey: .slot)
            try container.encode(charges, forKey: .charges)
            try container.encode(activeCount, forKey: .activeCount)
        case .operatorTriggered(let row, let slot, let shurikenId, let remaining):
            try container.encode(row, forKey: .row)
            try container.encode(slot, forKey: .slot)
            try container.encode(shurikenId, forKey: .shurikenId)
            try container.encode(remaining, forKey: .remainingCharges)
        case .gateTriggered(let type, let lane, let row, let result):
            try container.encode(type, forKey: .type)
            try container.encode(lane, forKey: .lane)
            try container.encode(row, forKey: .row)
            try container.encode(result, forKey: .result)
        case .shurikenBanked(let shurikenId, let bankColor):
            try container.encode(shurikenId, forKey: .shurikenId)
            try container.encode(bankColor, forKey: .bankColor)
        case .levelWin(let levelId, let usedOperators, let stars):
            try container.encode(levelId, forKey: .levelId)
            try container.encode(usedOperators, forKey: .usedOperators)
            try container.encode(stars, forKey: .stars)
        case .levelFail(let levelId, let reason, let remaining, let margin, let ops):
            try container.encode(levelId, forKey: .levelId)
            try container.encode(reason, forKey: .reason)
            try container.encode(remaining, forKey: .remainingToBank)
            try container.encodeIfPresent(margin, forKey: .overflowMargin)
            try container.encode(ops, forKey: .usedOperators)
        case .fixitOfferShown(let reason):
            try container.encode(reason, forKey: .reason)
        case .fixitOfferAccepted(let type):
            try container.encode(type, forKey: .type)
        case .adImpression(let format, let placement):
            try container.encode(format, forKey: .format)
            try container.encode(placement, forKey: .placement)
        case .purchase(let sku):
            try container.encode(sku, forKey: .sku)
        case .removeAdsEnabled(let enabled):
            try container.encode(enabled, forKey: .enabled)
        case .tutorialStepShown(let stepId, let levelId):
            try container.encode(stepId, forKey: .stepId)
            try container.encode(levelId, forKey: .levelId)
        case .tutorialStepCompleted(let stepId, let levelId, let durationMs):
            try container.encode(stepId, forKey: .stepId)
            try container.encode(levelId, forKey: .levelId)
            try container.encode(durationMs, forKey: .durationMs)
        case .preboostOfferShown(let type, let trigger):
            try container.encode(type, forKey: .type)
            try container.encode(trigger, forKey: .trigger)
        case .preboostOfferAccepted(let type, let choice):
            try container.encode(type, forKey: .type)
            try container.encode(choice, forKey: .choice)
        case .nearMissDetected(let type, let metric, let levelId):
            try container.encode(type, forKey: .type)
            try container.encode(metric, forKey: .proximityMetric)
            try container.encode(levelId, forKey: .levelId)
        case .currencyFlow(let source, let sink, let amount, let context):
            try container.encode(source, forKey: .source)
            try container.encode(sink, forKey: .sink)
            try container.encode(amount, forKey: .amount)
            try container.encode(context, forKey: .context)
        case .feedbackEvent(let type, let latencyMs):
            try container.encode(type, forKey: .type)
            try container.encode(latencyMs, forKey: .latencyMs)
        case .goalSalienceShown(let proximity, let banked):
            try container.encode(proximity, forKey: .proximityToWin)
            try container.encode(banked, forKey: .bankedCount)
        case .causalityTrace(let failReason, let eventChain):
            try container.encode(failReason, forKey: .failReason)
            try container.encode(eventChain, forKey: .eventChain)
        case .momentumWindowClosed(let accepted, let timeOpenMs):
            try container.encode(accepted, forKey: .accepted)
            try container.encode(timeOpenMs, forKey: .timeOpenMs)
        case .attemptCountDisplayed(let attempts, let coinsEarned):
            try container.encode(attempts, forKey: .attempts)
            try container.encode(coinsEarned, forKey: .coinsEarned)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case event
        case newStreak, questId, levelId, attemptId
        case row, slot, charges, activeCount
        case shurikenId, remainingCharges
        case type, lane, result
        case bankColor
        case usedOperators, stars
        case reason, remainingToBank, overflowMargin
        case format, placement
        case sku, enabled
        case stepId, durationMs
        case trigger, choice
        case proximityMetric
        case source, sink, amount, context
        case latencyMs
        case proximityToWin, bankedCount
        case failReason, eventChain
        case accepted, timeOpenMs
        case attempts, coinsEarned
    }
}
