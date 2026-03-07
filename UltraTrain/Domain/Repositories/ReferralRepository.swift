import Foundation

protocol ReferralRepository: Sendable {
    func getMyReferralCode() async throws -> ReferralInfo
    func applyReferralCode(_ code: String) async throws
}
