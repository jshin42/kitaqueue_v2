import SwiftUI

struct ShopView: View {
    @State private var iapManager = IAPManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(IAPProducts.allCases, id: \.rawValue) { iapProduct in
                            ProductCardView(
                                iapProduct: iapProduct,
                                storeProduct: iapManager.product(for: iapProduct),
                                isPurchased: iapManager.isPurchased(iapProduct),
                                onPurchase: {
                                    Task {
                                        guard let product = iapManager.product(for: iapProduct) else { return }
                                        _ = await iapManager.purchase(product)
                                    }
                                }
                            )
                        }

                        // Restore purchases
                        Button {
                            Task {
                                await iapManager.restorePurchases()
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Shop")
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                if iapManager.products.isEmpty {
                    await iapManager.loadProducts()
                }
            }
        }
    }
}
