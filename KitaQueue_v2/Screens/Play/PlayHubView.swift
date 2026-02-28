import SwiftUI

struct PlayHubView: View {
    let appState: AppState
    @State private var progression = PersistenceService.shared.loadProgression()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("KATA QUEUE")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top, 20)

                    Text("SLIDING GATES")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(4)

                    Spacer().frame(height: 20)

                    // Play Next CTA
                    Button {
                        appState.navigationPath.append(.gameplay(levelId: progression.currentLevel))
                    } label: {
                        VStack(spacing: 8) {
                            Text("PLAY NEXT")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("Level \(progression.currentLevel)")
                                .font(.system(size: 14, weight: .medium))
                                .opacity(0.8)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .padding(.horizontal, 24)

                    // Progress cards
                    HStack(spacing: 12) {
                        // Daily Kata card
                        CardView(
                            title: "Daily Kata",
                            subtitle: "0/3 Complete",
                            icon: "flame.fill",
                            color: .orange
                        )

                        // Belt Progress card
                        CardView(
                            title: beltName(for: progression.totalXP),
                            subtitle: "\(progression.totalXP) XP",
                            icon: "shield.fill",
                            color: beltColor(for: progression.totalXP)
                        )
                    }
                    .padding(.horizontal, 24)

                    // Campaign progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Campaign Progress")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            Text("Level \(progression.currentLevel)/100")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.cyan, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(progression.currentLevel) / 100.0)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.navigationPath.append(.settings)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func beltName(for xp: Int) -> String {
        switch xp {
        case 0..<500: "White Belt"
        case 500..<1500: "Yellow Belt"
        case 1500..<3000: "Orange Belt"
        case 3000..<5000: "Green Belt"
        case 5000..<8000: "Blue Belt"
        case 8000..<12000: "Purple Belt"
        case 12000..<17000: "Black Belt"
        default: "Red Belt"
        }
    }

    private func beltColor(for xp: Int) -> Color {
        switch xp {
        case 0..<500: .white
        case 500..<1500: .yellow
        case 1500..<3000: .orange
        case 3000..<5000: .green
        case 5000..<8000: .blue
        case 8000..<12000: .purple
        case 12000..<17000: .primary
        default: .red
        }
    }
}

private struct CardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.06))
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
