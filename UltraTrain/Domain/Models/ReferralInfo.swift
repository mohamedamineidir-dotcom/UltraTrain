import Foundation

struct ReferralInfo: Equatable, Sendable {
    let code: String
    let referralCount: Int
    /// Server-granted free-premium window from the referral reward. nil = none.
    var bonusAccessUntil: Date? = nil
    /// Whether the one-time +7-day referral reward has already been claimed.
    var rewardClaimed: Bool = false
    /// Whether this user joined via someone else's code (drives the "1/2 done"
    /// progress: joined ✓ → refer a friend to unlock their own 7 days).
    var wasReferred: Bool = false

    /// True when the referral bonus is currently granting free access.
    var hasActiveBonus: Bool {
        guard let until = bonusAccessUntil else { return false }
        return until > .now
    }

    /// Whole days of free access remaining from the bonus (0 if none/expired).
    var bonusDaysRemaining: Int {
        guard let until = bonusAccessUntil, until > .now else { return 0 }
        return Int((until.timeIntervalSinceNow / 86400).rounded(.up))
    }
}
