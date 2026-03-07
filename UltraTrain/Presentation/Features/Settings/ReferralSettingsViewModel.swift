import Foundation
import os

@Observable
@MainActor
final class ReferralSettingsViewModel {
    private let referralRepository: any ReferralRepository

    var referralCode: String?
    var referralCount: Int = 0
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
        } catch {
            Logger.app.error("Failed to load referral info: \(error)")
            self.error = "Could not load your referral code"
        }
    }

    var shareText: String {
        guard let code = referralCode else { return "" }
        return "Join me on UltraTrain! Use my referral code \(code) to get started: https://ultratrain.app/referral/\(code)"
    }
}
