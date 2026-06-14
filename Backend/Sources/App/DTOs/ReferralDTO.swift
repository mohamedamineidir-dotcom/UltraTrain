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
}

struct ApplyReferralRequest: Content, Validatable {
    let code: String

    static func validations(_ validations: inout Validations) {
        validations.add("code", as: String.self, is: .count(8...8) && .alphanumeric)
    }
}
