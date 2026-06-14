import Foundation
import os

@Observable
@MainActor
final class ReferralSettingsViewModel {
    private let referralRepository: any ReferralRepository

    var referralCode: String?
    var referralCount: Int = 0
    var bonusDaysRemaining: Int = 0
    var hasActiveBonus = false
    var rewardClaimed = false
    var wasReferred = false
    var isLoading = false
    var error: String?

    init(referralRepository: any ReferralRepository) {
        self.referralRepository = referralRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let info = try await referralRepository.getMyReferralCode()
            referralCode = info.code
            referralCount = info.referralCount
            bonusDaysRemaining = info.bonusDaysRemaining
            hasActiveBonus = info.hasActiveBonus
            rewardClaimed = info.rewardClaimed
            wasReferred = info.wasReferred
        } catch {
            Logger.app.error("Failed to load referral info: \(error)")
            self.error = "Could not load your referral code"
        }
    }

    var shareText: String {
        guard let code = referralCode else { return "" }
        return "Join me on UltraTrain and we both train smarter! Use my referral code \(code) and I get 7 days free: https://ultratrain.app/referral/\(code)"
    }
}
