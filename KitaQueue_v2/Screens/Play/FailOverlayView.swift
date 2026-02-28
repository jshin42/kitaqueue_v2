import SwiftUI

struct FailOverlayView: View {
    let coordinator: GameSceneCoordinator
    let appState: AppState
    let onRetry: () -> Void
    let onFixIt: () -> Void
    let onHome: () -> Void

    @State private var showContent = false

    private var failReason: FailReason? { coordinator.failReason }
    private var bankedCount: Int { coordinator.bankedCount }
    private var totalShuriken: Int { coordinator.totalShuriken }
    private var attemptNumber: Int { coordinator.attemptNumber }
    private var overflowMargin: Int? { coordinator.nearMissOverflowMargin }
    private var currentLevel: Int { coordinator.currentLevel }

    private var isOverflow: Bool {
        if case .overflow = failReason { return true }
        return false
    }

    private var failTitle: String {
        isOverflow ? CopyModel.failBannerOverflow : CopyModel.failBannerMisbank
    }

    private var nearMissText: String {
        if isOverflow {
            return "\(CopyModel.bankedMessage(banked: bankedCount, total: totalShuriken)) — \(CopyModel.overflowNearMiss)"
        } else {
            let remaining = totalShuriken - bankedCount
            return CopyModel.misbankNearMiss(remaining: remaining)
        }
    }

    private var canShowFixIt: Bool {
        // Fix It qualification: remainingToBank <= 3 OR overflowMargin == 1
        // Cap: 1 per attempt (first fail triggers overlay, so always first), 3 per session
        guard appState.sessionFixItCount < GameConstants.fixItMaxPerSession else { return false }

        if isOverflow {
            return true // Overflow always qualifies (margin was exactly 0 → was 1 before failing)
        } else {
            let remaining = totalShuriken - bankedCount
            return remaining <= 3
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Fail banner
                Text(failTitle)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0.0)

                // Near-miss stat
                Text(nearMissText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)

                // Attempt counter
                Text(CopyModel.attemptMessage(attempt: attemptNumber))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .opacity(showContent ? 1.0 : 0.0)

                Spacer().frame(height: 12)

                // Buttons
                VStack(spacing: 12) {
                    // Retry CTA
                    Button {
                        SoundManager.shared.playButtonTap()
                        onRetry()
                    } label: {
                        Text(CopyModel.retry)
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

                    // Fix It button (conditional)
                    if canShowFixIt {
                        Button {
                            SoundManager.shared.playButtonTap()
                            onFixIt()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.system(size: 14))
                                Text(isOverflow ? CopyModel.fixItOverflow : CopyModel.fixItMisbank)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                if currentLevel > GameConstants.fixItFreeUntilLevel {
                                    // Show "ad" indicator after FTUE
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .teal],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
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
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
        }
    }
}
