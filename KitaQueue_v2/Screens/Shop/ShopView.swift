import SwiftUI

struct ShopView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Remove Ads
                        ProductCardPlaceholder(
                            title: "Remove Ads",
                            subtitle: "Eliminate interstitial ads forever",
                            icon: "xmark.circle.fill",
                            color: .cyan
                        )

                        // Starter Pack
                        ProductCardPlaceholder(
                            title: "Starter Pack",
                            subtitle: "Remove Ads + 200 Coins + 5 Tokens + Exclusive Skin",
                            icon: "star.fill",
                            color: .yellow
                        )

                        // Cosmetics
                        ProductCardPlaceholder(
                            title: "Dojo Theme Pack",
                            subtitle: "Premium dojo visual theme",
                            icon: "paintbrush.fill",
                            color: .purple
                        )

                        ProductCardPlaceholder(
                            title: "Blade Trail Pack",
                            subtitle: "Premium blade trail effects",
                            icon: "sparkles",
                            color: .orange
                        )
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Shop")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct ProductCardPlaceholder: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text("$--.--")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.08))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.06))
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
