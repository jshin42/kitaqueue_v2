import SwiftUI

struct WinOverlayView: View {
    let coordinator: GameSceneCoordinator
    let appState: AppState
    let onNext: () -> Void
    let onHome: () -> Void

    @State private var showStars = false
    @State private var showContent = false

    private var stars: Int { coordinator.starRating }
    private var operatorsUsed: Int { coordinator.operatorsUsed }
    private var bankedCount: Int { coordinator.bankedCount }
    private var totalShuriken: Int { coordinator.totalShuriken }
    private var currentLevel: Int { coordinator.currentLevel }

    private var missedBy: Int? {
        StarCalculator.missedThreeStarBy(
            operatorsUsed: operatorsUsed,
            threeStarMax: coordinator.parThreshold
        )
    }

    private var coinsEarned: Int { StarCalculator.coins(stars: stars) }
    private var xpEarned: Int { StarCalculator.xp(stars: stars) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // CLEAR banner
                Text(CopyModel.clearBanner)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)

                // Stars
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundStyle(i <= stars ? .yellow : .white.opacity(0.3))
                            .scaleEffect(showStars && i <= stars ? 1.0 : 0.5)
                            .opacity(showStars ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.6)
                                    .delay(Double(i) * 0.2),
                                value: showStars
                            )
                    }
                }

                // Missed 3-star message
                if let missed = missedBy {
                    Text(CopyModel.missedThreeStarMessage(by: missed))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(showContent ? 1.0 : 0.0)
                }

                // Stats
                VStack(spacing: 8) {
                    Text(CopyModel.bankedMessage(banked: bankedCount, total: totalShuriken))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack(spacing: 16) {
                        Label("+\(coinsEarned)", systemImage: "circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.yellow)
                        Label("+\(xpEarned) XP", systemImage: "bolt.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.cyan)
                    }
                }
                .opacity(showContent ? 1.0 : 0.0)

                // Campaign progress
                VStack(spacing: 4) {
                    Text("Level \(currentLevel)/\(GameConstants.totalCampaignLevels)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(currentLevel) / CGFloat(GameConstants.totalCampaignLevels))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 40)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer().frame(height: 12)

                // Buttons
                VStack(spacing: 12) {
                    // Next CTA
                    Button {
                        SoundManager.shared.playButtonTap()
                        onNext()
                    } label: {
                        Text(CopyModel.next)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    // Home button
                    Button {
                        SoundManager.shared.playButtonTap()
                        onHome()
                    } label: {
                        Label(CopyModel.home, systemImage: "house.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 40)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                showStars = true
            }
        }
    }
}
