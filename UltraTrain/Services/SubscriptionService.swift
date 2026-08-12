import Foundation
import StoreKit
import os

final class SubscriptionService: SubscriptionServiceProtocol, @unchecked Sendable {

    // Disambiguate from StoreKit's identically-named types
    typealias Status = UltraTrain.SubscriptionStatus
    typealias Period = UltraTrain.SubscriptionPeriod

    // MARK: - Constants

    // The "UltraTrain Premium" group/products (com.ultratrain.app.premium.*)
    // were abandoned — its App Store Connect state got stuck and could
    // never complete its first review submission. "UltraTrain Access" is a
    // fresh group with new product IDs to route around that stuck state.
    private static let productIds: Set<String> = [
        "com.ultratrain.app.access.monthly",
        "com.ultratrain.app.access.yearly"
    ]

    // MARK: - Cache Keys

    private static let cachedActiveKey = "subscription_is_active"
    private static let cachedProductIdKey = "subscription_product_id"
    private static let cachedExpirationKey = "subscription_expiration"
    private static let cachedTrialKey = "subscription_is_trial"

    // MARK: - State

    private(set) var currentStatus: Status = .inactive
    private var products: [Product] = []
    private var updateTask: Task<Void, Never>?

    // Multicast: each caller of `statusUpdates` gets its OWN stream, and every
    // status change is broadcast to all of them. A single shared AsyncStream
    // SPLITS events between consumers — and both the premium gate (MainTabView)
    // and AppRootView listen — so a purchase could reach only one, leaving
    // premium features locked until the next event. This guarantees both see it.
    private let continuationsLock = NSLock()
    private var continuations: [UUID: AsyncStream<Status>.Continuation] = [:]

    var statusUpdates: AsyncStream<Status> {
        AsyncStream { continuation in
            let id = UUID()
            continuationsLock.lock()
            continuations[id] = continuation
            continuationsLock.unlock()
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.continuationsLock.lock()
                self.continuations[id] = nil
                self.continuationsLock.unlock()
            }
        }
    }

    private func broadcast(_ status: Status) {
        continuationsLock.lock()
        let conts = Array(continuations.values)
        continuationsLock.unlock()
        for c in conts { c.yield(status) }
    }

    // MARK: - Init

    init() {
        // Restore cached status so the app doesn't show the paywall on relaunch
        // while StoreKit verifies in the background
        if UserDefaults.standard.bool(forKey: Self.cachedActiveKey) {
            currentStatus = Status(
                isActive: true,
                tier: .premium,
                expirationDate: UserDefaults.standard.object(forKey: Self.cachedExpirationKey) as? Date,
                isInTrialPeriod: UserDefaults.standard.bool(forKey: Self.cachedTrialKey),
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
                    self.broadcast(status)
                }
            }
        }
    }

    deinit {
        updateTask?.cancel()
        continuationsLock.lock()
        continuations.values.forEach { $0.finish() }
        continuations.removeAll()
        continuationsLock.unlock()
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
            .first { $0.id.contains("monthly") }?.price ?? Decimal(string: "14.99")!

        return products
            .sorted { periodOrder($0) < periodOrder($1) }
            .map { product in
                let period = mapPeriod(product.id)
                let weeksInPeriod: Decimal = switch period {
                case .monthly: Decimal(string: "4.33")!
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
                    case .yearly: 12
                    }
                    let totalIfMonthly = monthlyDouble * monthsInPeriod
                    let actualPrice = NSDecimalNumber(decimal: product.price).doubleValue
                    let pct = Int(((totalIfMonthly - actualPrice) / totalIfMonthly) * 100)
                    return pct > 0 ? pct : nil
                }()

                return SubscriptionPlan(
                    id: product.id,
                    period: period,
                    price: product.price,
                    pricePerWeek: pricePerWeek,
                    displayPrice: product.displayPrice,
                    displayPricePerWeek: formatPrice(pricePerWeek, locale: product.priceFormatStyle.locale),
                    savingsPercent: savings
                )
            }
    }

    // MARK: - Purchase

    func purchase(productId: String) async throws -> Status {
        Logger.subscription.info("SubscriptionService.purchase called for: \(productId)")
        Logger.subscription.info("Available products: \(self.products.map(\.id))")

        guard let product = products.first(where: { $0.id == productId }) else {
            Logger.subscription.error("Product not found in loaded products!")
            throw DomainError.purchaseFailed(reason: "Product not found.")
        }

        let result: Product.PurchaseResult
        do {
            Logger.subscription.info("Calling product.purchase()...")
            result = try await product.purchase()
            Logger.subscription.info("product.purchase() returned")
        } catch {
            Logger.subscription.error("Purchase error: \(error)")
            throw DomainError.purchaseFailed(reason: error.localizedDescription)
        }

        switch result {
        case .success(let verification):
            Logger.subscription.info("Purchase result: .success")
            switch verification {
            case .verified(let transaction):
                Logger.subscription.info("Transaction verified: productID=\(transaction.productID), expiration=\(String(describing: transaction.expirationDate)), revocation=\(String(describing: transaction.revocationDate))")
                await transaction.finish()
                let isExpired = transaction.expirationDate.map { $0 < Date.now } ?? false
                Logger.subscription.info("isExpired=\(isExpired)")
                let status = Status(
                    isActive: transaction.revocationDate == nil && !isExpired,
                    tier: .premium,
                    expirationDate: transaction.expirationDate,
                    isInTrialPeriod: transaction.offerType == .introductory,
                    willAutoRenew: !isExpired,
                    productId: transaction.productID
                )
                Logger.subscription.info("Built status: isActive=\(status.isActive)")
                currentStatus = status
                cacheStatus(status)
                broadcast(status)
                return status

            case .unverified(let transaction, let error):
                Logger.subscription.error("Transaction UNVERIFIED: \(error), productID=\(transaction.productID)")
                throw DomainError.purchaseFailed(reason: "Transaction could not be verified.")
            }

        case .pending:
            Logger.subscription.info("Purchase result: .pending")
            return currentStatus

        case .userCancelled:
            Logger.subscription.info("Purchase result: .userCancelled")
            #if DEBUG
            // StoreKit testing on iOS Simulator may auto-cancel the purchase dialog.
            // Treat as success in debug builds so the full app flow can be tested.
            Logger.subscription.info("DEBUG: bypassing .userCancelled as active subscription")
            let debugStatus = Status(
                isActive: true,
                tier: .premium,
                expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isInTrialPeriod: false,
                willAutoRenew: true,
                productId: productId
            )
            currentStatus = debugStatus
            cacheStatus(debugStatus)
            broadcast(debugStatus)
            return debugStatus
            #else
            return currentStatus
            #endif

        @unknown default:
            Logger.subscription.info("Purchase result: @unknown default")
            return currentStatus
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws -> Status {
        try await AppStore.sync()
        let status = await refreshStatus()
        broadcast(status)
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
            #if DEBUG
            // Preserve the debug bypass status when no real StoreKit entitlements exist
            if currentStatus.isActive {
                return currentStatus
            }
            #endif
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
        product.id.contains("yearly") ? 0 : 1
    }

    private func mapPeriod(_ productId: String) -> Period {
        productId.contains("monthly") ? .monthly : .yearly
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
        UserDefaults.standard.set(status.isInTrialPeriod, forKey: Self.cachedTrialKey)
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
