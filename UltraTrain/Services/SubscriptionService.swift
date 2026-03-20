import Foundation
import StoreKit
import os

final class SubscriptionService: SubscriptionServiceProtocol, @unchecked Sendable {

    // Disambiguate from StoreKit's identically-named types
    typealias Status = UltraTrain.SubscriptionStatus
    typealias Period = UltraTrain.SubscriptionPeriod

    // MARK: - Constants

    private static let productIds: Set<String> = [
        "com.ultratrain.app.premium.monthly",
        "com.ultratrain.app.premium.quarterly",
        "com.ultratrain.app.premium.yearly"
    ]

    // MARK: - Cache Keys

    private static let cachedActiveKey = "subscription_is_active"
    private static let cachedProductIdKey = "subscription_product_id"
    private static let cachedExpirationKey = "subscription_expiration"

    // MARK: - State

    private(set) var currentStatus: Status = .inactive
    private var products: [Product] = []
    private var updateTask: Task<Void, Never>?
    private let statusContinuation: AsyncStream<Status>.Continuation
    let statusUpdates: AsyncStream<Status>

    // MARK: - Init

    init() {
        let (stream, continuation) = AsyncStream<Status>.makeStream()
        self.statusUpdates = stream
        self.statusContinuation = continuation

        // Restore cached status so the app doesn't show the paywall on relaunch
        // while StoreKit verifies in the background
        if UserDefaults.standard.bool(forKey: Self.cachedActiveKey) {
            currentStatus = Status(
                isActive: true,
                tier: .premium,
                expirationDate: UserDefaults.standard.object(forKey: Self.cachedExpirationKey) as? Date,
                isInTrialPeriod: false,
                willAutoRenew: true,
                productId: UserDefaults.standard.string(forKey: Self.cachedProductIdKey)
            )
        }

        updateTask = Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    let status = await self.refreshStatus()
                    self.statusContinuation.yield(status)
                }
            }
        }
    }

    deinit {
        updateTask?.cancel()
        statusContinuation.finish()
    }

    // MARK: - Fetch Plans

    func fetchPlans() async throws -> [SubscriptionPlan] {
        do {
            products = try await Product.products(for: Self.productIds)
        } catch {
            Logger.subscription.error("Failed to fetch products: \(error)")
            throw DomainError.purchaseFailed(reason: "Could not load subscription plans.")
        }

        let monthlyPrice = products
            .first { $0.id.contains("monthly") }?.price ?? Decimal(string: "19.99")!

        return products
            .sorted { periodOrder($0) < periodOrder($1) }
            .map { product in
                let period = mapPeriod(product.id)
                let weeksInPeriod: Decimal = switch period {
                case .monthly: Decimal(string: "4.33")!
                case .quarterly: 13
                case .yearly: 52
                }
                let pricePerWeek = product.price / weeksInPeriod

                // Calculate savings vs monthly using Double for reliable percentage
                let savings: Int? = {
                    guard period != .monthly else { return nil }
                    let monthlyDouble = NSDecimalNumber(decimal: monthlyPrice).doubleValue
                    guard monthlyDouble > 0 else { return nil }
                    let monthsInPeriod: Double = switch period {
                    case .monthly: 1
                    case .quarterly: 3
                    case .yearly: 12
                    }
                    let totalIfMonthly = monthlyDouble * monthsInPeriod
                    let actualPrice = NSDecimalNumber(decimal: product.price).doubleValue
                    let pct = Int(((totalIfMonthly - actualPrice) / totalIfMonthly) * 100)
                    return pct > 0 ? pct : nil
                }()

                let trialDays: Int? = if product.subscription?.introductoryOffer != nil {
                    7
                } else {
                    nil
                }

                return SubscriptionPlan(
                    id: product.id,
                    period: period,
                    price: product.price,
                    pricePerWeek: pricePerWeek,
                    displayPrice: product.displayPrice,
                    displayPricePerWeek: formatPrice(pricePerWeek, locale: product.priceFormatStyle.locale),
                    savingsPercent: savings,
                    trialDays: trialDays
                )
            }
    }

    // MARK: - Purchase

    func purchase(productId: String) async throws -> Status {
        guard let product = products.first(where: { $0.id == productId }) else {
            throw DomainError.purchaseFailed(reason: "Product not found.")
        }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            Logger.subscription.error("Purchase error: \(error)")
            throw DomainError.purchaseFailed(reason: error.localizedDescription)
        }

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw DomainError.purchaseFailed(reason: "Transaction could not be verified.")
            }
            await transaction.finish()
            // Build status directly from the verified transaction to avoid
            // timing issues where Transaction.currentEntitlements hasn't updated yet
            let isExpired = transaction.expirationDate.map { $0 < Date.now } ?? false
            let status = Status(
                isActive: transaction.revocationDate == nil && !isExpired,
                tier: .premium,
                expirationDate: transaction.expirationDate,
                isInTrialPeriod: transaction.offerType == .introductory,
                willAutoRenew: !isExpired,
                productId: transaction.productID
            )
            currentStatus = status
            cacheStatus(status)
            statusContinuation.yield(status)
            return status

        case .pending:
            Logger.subscription.info("Purchase pending (Ask to Buy or SCA)")
            return currentStatus

        case .userCancelled:
            Logger.subscription.info("User cancelled purchase")
            return currentStatus

        @unknown default:
            return currentStatus
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws -> Status {
        try await AppStore.sync()
        let status = await refreshStatus()
        statusContinuation.yield(status)
        return status
    }

    // MARK: - Refresh Status

    func refreshStatus() async -> Status {
        var latestTransaction: Transaction?

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    if latestTransaction == nil ||
                        transaction.purchaseDate > latestTransaction!.purchaseDate {
                        latestTransaction = transaction
                    }
                }
            }
        }

        guard let transaction = latestTransaction else {
            currentStatus = .inactive
            cacheStatus(.inactive)
            return .inactive
        }

        let isExpired = transaction.expirationDate.map { $0 < Date.now } ?? false
        let status = Status(
            isActive: transaction.revocationDate == nil && !isExpired,
            tier: .premium,
            expirationDate: transaction.expirationDate,
            isInTrialPeriod: transaction.offerType == .introductory,
            willAutoRenew: !isExpired,
            productId: transaction.productID
        )
        currentStatus = status
        cacheStatus(status)
        return status
    }

    // MARK: - Helpers

    private func periodOrder(_ product: Product) -> Int {
        if product.id.contains("yearly") { return 0 }
        if product.id.contains("quarterly") { return 1 }
        return 2
    }

    private func mapPeriod(_ productId: String) -> Period {
        if productId.contains("monthly") { return .monthly }
        if productId.contains("quarterly") { return .quarterly }
        return .yearly
    }

    private func formatPrice(_ price: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        return formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
    }

    private func cacheStatus(_ status: Status) {
        UserDefaults.standard.set(status.isActive, forKey: Self.cachedActiveKey)
        UserDefaults.standard.set(status.productId, forKey: Self.cachedProductIdKey)
        UserDefaults.standard.set(status.expirationDate, forKey: Self.cachedExpirationKey)
    }
}

private extension Decimal {
    func rounded() -> Decimal {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, 0, .plain)
        return result
    }
}
