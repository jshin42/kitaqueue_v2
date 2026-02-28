import SwiftUI

struct DailyView: View {
    @State private var dailyState = PersistenceService.shared.loadDailyState()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Daily Pack header
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)
                            Text("Daily Kata")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Complete 3 levels to earn a Technique Token")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 40)

                        // Streak badge
                        if dailyState.streakCount > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.orange)
                                Text("\(dailyState.streakCount) day streak")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(.orange.opacity(0.15))
                            )
                        }

                        // Pack progress
                        HStack(spacing: 16) {
                            ForEach(0..<3, id: \.self) { i in
                                let completed = i < dailyState.packProgress
                                Circle()
                                    .fill(completed ? .green : .white.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if completed {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(.white)
                                        } else {
                                            Text("\(i + 1)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                    }
                            }
                        }

                        // Pack completion reward
                        if dailyState.packComplete {
                            HStack(spacing: 6) {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(.yellow)
                                Text("+1 Technique Token earned!")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.yellow)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.yellow.opacity(0.1))
                            )
                        }

                        Divider().overlay(.white.opacity(0.1))

                        // Daily Quests
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Daily Quests")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(dailyState.completedQuestTokens)/\(dailyState.totalQuestTokens) tokens")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.yellow.opacity(0.7))
                            }

                            if dailyState.quests.isEmpty {
                                Text("Play a level to generate today's quests")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(dailyState.quests) { quest in
                                    QuestRowView(quest: quest)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Daily")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            dailyState.ensureCurrent()
            PersistenceService.shared.saveDailyState(dailyState)
        }
    }
}
