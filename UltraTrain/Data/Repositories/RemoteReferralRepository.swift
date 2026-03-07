import Foundation
import os

final class RemoteReferralRepository: ReferralRepository, Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getMyReferralCode() async throws -> ReferralInfo {
        let dto: ReferralCodeResponseDTO = try await apiClient.send(
            ReferralEndpoints.GetMyCode()
        )
        return ReferralInfo(code: dto.referralCode, referralCount: dto.referralCount)
    }

    func applyReferralCode(_ code: String) async throws {
        let _: MessageResponseDTO = try await apiClient.send(
            ReferralEndpoints.ApplyCode(code: code)
        )
    }
}
