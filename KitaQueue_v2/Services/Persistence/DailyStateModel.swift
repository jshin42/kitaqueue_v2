import Foundation

struct DailyStateModel: Codable, Equatable {
    var lastPlayedDate: String = ""
    var packProgress: Int = 0 // 0-3 levels completed today
    var streakCount: Int = 0
    var quests: [DailyQuest] = []

    // MARK: - Date Handling

    static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var isToday: Bool {
        lastPlayedDate == Self.todayString
    }

    var packComplete: Bool {
        packProgress >= 3
    }

    // MARK: - Daily Reset

    /// Returns a state that is current for today. Resets pack/quests if it's a new day.
    mutating func ensureCurrent() {
        let today = Self.todayString
        guard lastPlayedDate != today else { return }

        // Check streak: if yesterday, increment; otherwise reset
        if let lastDate = Self.date(from: lastPlayedDate),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           Calendar.current.isDate(lastDate, inSameDayAs: yesterday),
           packComplete {
            streakCount += 1
        } else if lastPlayedDate.isEmpty {
            // First day, start streak at 0
        } else {
            streakCount = 0
        }

        lastPlayedDate = today
        packProgress = 0
        quests = Self.generateQuests(for: today)
    }

    // MARK: - Quest Generation

    static func generateQuests(for dateString: String) -> [DailyQuest] {
        // Deterministic seed from date string
        let seed = dateString.hashValue
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))

        let pool: [(id: String, desc: String, target: Int, tokens: Int)] = [
            ("bank_30", "Bank 30 shuriken", 30, 1),
            ("win_3_par", "Win 3 levels with 3 stars", 3, 2),
            ("win_2_clean", "Win 2 levels without misbank", 2, 1),
            ("bank_50", "Bank 50 shuriken", 50, 2),
            ("place_10_ops", "Place 10 operators", 10, 1),
            ("win_5", "Win 5 levels", 5, 2),
        ]

        // Pick 3 unique quests
        var indices = Array(0..<pool.count)
        var selected: [DailyQuest] = []
        for _ in 0..<3 {
            let idx = Int(rng.next() % UInt64(indices.count))
            let poolIdx = indices.remove(at: idx)
            let q = pool[poolIdx]
            selected.append(DailyQuest(
                id: q.id,
                description: q.desc,
                targetCount: q.target,
                rewardTokens: q.tokens
            ))
        }
        return selected
    }

    // MARK: - Quest Progress

    mutating func updateQuestProgress(banked: Int, won: Bool, stars: Int, misbanked: Bool, operatorsPlaced: Int) {
        for i in quests.indices {
            guard !quests[i].isCompleted else { continue }

            switch quests[i].id {
            case "bank_30", "bank_50":
                quests[i].currentCount += banked
            case "win_3_par":
                if won && stars >= 3 { quests[i].currentCount += 1 }
            case "win_2_clean":
                if won && !misbanked { quests[i].currentCount += 1 }
            case "place_10_ops":
                quests[i].currentCount += operatorsPlaced
            case "win_5":
                if won { quests[i].currentCount += 1 }
            default:
                break
            }
        }
    }

    var completedQuestTokens: Int {
        quests.filter(\.isCompleted).reduce(0) { $0 + $1.rewardTokens }
    }

    var totalQuestTokens: Int {
        quests.reduce(0) { $0 + $1.rewardTokens }
    }

    // MARK: - Helpers

    private static func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

struct DailyQuest: Codable, Equatable, Identifiable {
    let id: String
    let description: String
    let targetCount: Int
    var currentCount: Int = 0
    let rewardTokens: Int

    var isCompleted: Bool { currentCount >= targetCount }
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(targetCount))
    }
}

/// Simple seeded RNG for deterministic quest selection
private struct SeededRNG {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
