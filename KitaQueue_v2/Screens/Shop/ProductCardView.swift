import SwiftUI
import StoreKit

struct ProductCardView: View {
    let iapProduct: IAPProducts
    let storeProduct: Product?
    let isPurchased: Bool
    let onPurchase: () -> Void

    @State private var purchasing = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iapProduct.icon)
                .font(.title)
                .foregroundStyle(accentColor)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(iapProduct.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(iapProduct.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            } else if purchasing {
                ProgressView()
                    .tint(.white)
            } else {
                Button {
                    purchasing = true
                    onPurchase()
                    // Reset after brief delay (purchase result handled externally)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        purchasing = false
                    }
                } label: {
                    Text(storeProduct?.displayPrice ?? "$--.--")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.3))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(isPurchased ? 0.03 : 0.06))
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var accentColor: Color {
        switch iapProduct.accentColorName {
        case "cyan": .cyan
        case "yellow": .yellow
        case "purple": .purple
        case "orange": .orange
        default: .white
        }
    }
}
