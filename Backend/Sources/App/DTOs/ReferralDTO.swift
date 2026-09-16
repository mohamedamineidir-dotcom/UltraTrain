import Vapor

struct ReferralCodeResponse: Content {
    let referralCode: String
    let referralCount: Int
    /// Server-granted free-premium window (referral reward), epoch seconds.
    /// nil = none.
    let bonusAccessUntil: Double?
    /// Whether this user has already claimed their one-time referral reward.
    let rewardClaimed: Bool
    /// Whether this user signed up via someone else's code (drives the
    /// "1/2 done" progress nudge to refer a friend and unlock their reward).
    let wasReferred: Bool
    /// Server-granted free-premium window from an active website (Stripe)
    /// subscription, epoch seconds. nil = none. Bundled onto this response
    /// (rather than a separate endpoint) since the app already fetches this
    /// non-blocking on launch to widen the StoreKit entitlement check.
    let webPremiumUntil: Double?
}

struct ApplyReferralRequest: Content, Validatable {
    let code: String

    static func validations(_ validations: inout Validations) {
        validations.add("code", as: String.self, is: .count(8...8) && .alphanumeric)
    }
}
