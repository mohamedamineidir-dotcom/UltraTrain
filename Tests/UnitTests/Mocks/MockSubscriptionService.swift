import Foundation
@testable import UltraTrain

final class MockSubscriptionService: SubscriptionServiceProtocol, @unchecked Sendable {
    var currentStatus: SubscriptionStatus = .inactive

    var plansToReturn: [SubscriptionPlan] = []
    var shouldThrowOnFetch = false
    var shouldThrowOnPurchase = false
    var shouldThrowOnRestore = false
    var purchaseCalled = false
    var restoreCalled = false
    var purchasedProductId: String?
    var statusAfterPurchase: SubscriptionStatus?

    let statusUpdates: AsyncStream<SubscriptionStatus>
    private let continuation: AsyncStream<SubscriptionStatus>.Continuation

    init() {
        let (stream, cont) = AsyncStream<SubscriptionStatus>.makeStream()
        statusUpdates = stream
        continuation = cont
    }

    func fetchPlans() async throws -> [SubscriptionPlan] {
        if shouldThrowOnFetch {
            throw DomainError.purchaseFailed(reason: "Mock fetch error")
        }
        return plansToReturn
    }

    func purchase(productId: String) async throws -> SubscriptionStatus {
        purchaseCalled = true
        purchasedProductId = productId
        if shouldThrowOnPurchase {
            throw DomainError.purchaseFailed(reason: "Mock purchase error")
        }
        let status = statusAfterPurchase ?? SubscriptionStatus(
            isActive: true,
            tier: .premium,
            expirationDate: Date.now.addingTimeInterval(86400 * 30),
            isInTrialPeriod: true,
            willAutoRenew: true,
            productId: productId
        )
        currentStatus = status
        return status
    }

    func restorePurchases() async throws -> SubscriptionStatus {
        restoreCalled = true
        if shouldThrowOnRestore {
            throw DomainError.purchaseFailed(reason: "Mock restore error")
        }
        return currentStatus
    }

    func refreshStatus() async -> SubscriptionStatus {
        currentStatus
    }
}
