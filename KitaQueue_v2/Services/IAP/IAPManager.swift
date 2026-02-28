import StoreKit
import SwiftUI

/// Typealias to disambiguate StoreKit Transaction from other Transaction types
private typealias SKTransaction = StoreKit.Transaction

/// StoreKit 2 manager for IAP products, purchases, and restore.
@MainActor @Observable
final class IAPManager {
    static let shared = IAPManager()

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
    }

    nonisolated deinit {
        // Cannot cancel from nonisolated context; task will end naturally when no strong refs remain
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let ids = IAPProducts.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            products = []
        }

        await refreshPurchasedState()
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let txn = try checkVerified(verification)
                await handlePurchase(product: product)
                await txn.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshPurchasedState()
    }

    // MARK: - State

    func isPurchased(_ productId: String) -> Bool {
        purchasedProductIDs.contains(productId)
    }

    func isPurchased(_ product: IAPProducts) -> Bool {
        isPurchased(product.rawValue)
    }

    func product(for iapProduct: IAPProducts) -> Product? {
        products.first { $0.id == iapProduct.rawValue }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in SKTransaction.updates {
                if let txn = try? result.payloadValue {
                    await self?.handleTransactionUpdate(txn)
                    await txn.finish()
                }
            }
        }
    }

    private func refreshPurchasedState() async {
        var purchased: Set<String> = []
        for await result in SKTransaction.currentEntitlements {
            if let txn = try? checkVerified(result) {
                purchased.insert(txn.productID)
            }
        }
        purchasedProductIDs = purchased
        applyPurchaseEffects()
    }

    private func handleTransactionUpdate(_ txn: SKTransaction) async {
        purchasedProductIDs.insert(txn.productID)
        applyPurchaseEffects()
    }

    private func handlePurchase(product: Product) async {
        purchasedProductIDs.insert(product.id)
        applyPurchaseEffects()

        // Apply one-time rewards
        if product.id == IAPProducts.starterPack.rawValue {
            var progression = PersistenceService.shared.loadProgression()
            progression.totalCoins += 200
            progression.totalTokens += 5
            PersistenceService.shared.saveProgression(progression)
        }
    }

    private func applyPurchaseEffects() {
        var settings = PersistenceService.shared.loadSettings()
        let wasRemoved = settings.adsRemoved

        if purchasedProductIDs.contains(IAPProducts.removeAds.rawValue) ||
           purchasedProductIDs.contains(IAPProducts.starterPack.rawValue) {
            settings.adsRemoved = true
        }

        if settings.adsRemoved != wasRemoved {
            PersistenceService.shared.saveSettings(settings)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
