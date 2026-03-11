import Foundation

enum SubscriptionPeriod: String, Sendable, Equatable, CaseIterable {
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        }
    }

    var displayNameLocalized: String {
        switch self {
        case .monthly: String(localized: "paywall.monthly")
        case .quarterly: String(localized: "paywall.quarterly")
        case .yearly: String(localized: "paywall.yearly")
        }
    }
}

struct SubscriptionPlan: Identifiable, Sendable, Equatable {
    let id: String
    let period: SubscriptionPeriod
    let price: Decimal
    let pricePerWeek: Decimal
    let displayPrice: String
    let displayPricePerWeek: String
    let savingsPercent: Int?
    let trialDays: Int?
}
