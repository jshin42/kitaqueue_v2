import SwiftUI

struct DailyView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

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

                    // Pack progress
                    HStack(spacing: 16) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Text("\(i + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                        }
                    }

                    Divider().overlay(.white.opacity(0.1))

                    // Quests placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Quests")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Coming soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Daily")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
