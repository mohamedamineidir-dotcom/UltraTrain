import Foundation

protocol SubscriptionServiceProtocol: Sendable {
    var currentStatus: SubscriptionStatus { get }
    var statusUpdates: AsyncStream<SubscriptionStatus> { get }

    func fetchPlans() async throws -> [SubscriptionPlan]
    func purchase(productId: String) async throws -> SubscriptionStatus
    func restorePurchases() async throws -> SubscriptionStatus
    func refreshStatus() async -> SubscriptionStatus
}
