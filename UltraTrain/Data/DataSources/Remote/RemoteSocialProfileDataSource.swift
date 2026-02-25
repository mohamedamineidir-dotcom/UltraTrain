import Foundation

final class RemoteSocialProfileDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchMyProfile() async throws -> SocialProfileResponseDTO {
        try await apiClient.send(SocialEndpoints.FetchMyProfile())
    }

    func updateMyProfile(_ dto: SocialProfileUpdateRequestDTO) async throws -> SocialProfileResponseDTO {
        try await apiClient.send(SocialEndpoints.UpdateProfile(body: dto))
    }

    func fetchProfile(id: String) async throws -> SocialProfileResponseDTO {
        try await apiClient.send(SocialEndpoints.FetchProfile(id: id))
    }

    func searchProfiles(query: String) async throws -> [SocialProfileResponseDTO] {
        try await apiClient.send(SocialEndpoints.Search(query: query))
    }
}
