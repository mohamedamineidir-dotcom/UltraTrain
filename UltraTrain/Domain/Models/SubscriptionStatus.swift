import Foundation

enum SubscriptionTier: String, Sendable, Equatable {
    case none
    case premium
}

struct SubscriptionStatus: Sendable, Equatable {
    let isActive: Bool
    let tier: SubscriptionTier
    let expirationDate: Date?
    let isInTrialPeriod: Bool
    let willAutoRenew: Bool
    let productId: String?

    var period: SubscriptionPeriod? {
        guard let productId, isActive else { return nil }
        if productId.contains("monthly") { return .monthly }
        if productId.contains("quarterly") { return .quarterly }
        if productId.contains("yearly") { return .yearly }
        return nil
    }

    static let inactive = SubscriptionStatus(
        isActive: false,
        tier: .none,
        expirationDate: nil,
        isInTrialPeriod: false,
        willAutoRenew: false,
        productId: nil
    )
}
