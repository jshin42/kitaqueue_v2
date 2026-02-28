import Foundation

struct DailyStateModel: Codable, Equatable {
    var lastPlayedDate: String = ""
    var packProgress: Int = 0 // 0-3 levels completed today
    var streakCount: Int = 0
    var quests: [DailyQuest] = []
}

struct DailyQuest: Codable, Equatable, Identifiable {
    let id: String
    let description: String
    let targetCount: Int
    var currentCount: Int = 0
    let rewardTokens: Int

    var isCompleted: Bool { currentCount >= targetCount }
}
