import Foundation
import StoreKit

/// Manages StoreKit purchases and subscriptions
@MainActor
public final class StoreKitManager: ObservableObject {

    public static let shared = StoreKitManager()

    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedSubscriptions: [Product] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: String?

    private var updateListenerTask: Task<Void, Error>?

    // Product identifiers
    private let productIds = [
        "com.strainlab.premium.monthly",
        "com.strainlab.premium.yearly"
    ]

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    public func loadProducts() async {
        isLoading = true
        error = nil

        do {
            products = try await Product.products(for: productIds)
            products.sort { $0.price < $1.price }
        } catch {
            self.error = "Failed to load products: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Purchase

    public func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Handling

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    @MainActor
    private func updatePurchasedProducts() async {
        var purchased: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchased.append(product)
                }
            } catch {
                print("Failed to verify entitlement: \(error)")
            }
        }

        purchasedSubscriptions = purchased

        // Update premium manager
        if !purchased.isEmpty {
            PremiumManager.shared.upgradeToPremium()
        }
    }

    // MARK: - Helpers

    public var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }

    public var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }

    public func isPurchased(_ product: Product) -> Bool {
        purchasedSubscriptions.contains { $0.id == product.id }
    }
}

// MARK: - Errors

enum StoreError: Error, LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed"
        }
    }
}
