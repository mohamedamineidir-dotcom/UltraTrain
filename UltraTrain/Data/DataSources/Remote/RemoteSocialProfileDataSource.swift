import Foundation

final class RemoteSocialProfileDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchMyProfile() async throws -> SocialProfileResponseDTO {
        try await apiClient.request(
            path: SocialEndpoints.profilePath,
            method: .get,
            requiresAuth: true
        )
    }

    func updateMyProfile(_ dto: SocialProfileUpdateRequestDTO) async throws -> SocialProfileResponseDTO {
        try await apiClient.request(
            path: SocialEndpoints.profilePath,
            method: .put,
            body: dto,
            requiresAuth: true
        )
    }

    func fetchProfile(id: String) async throws -> SocialProfileResponseDTO {
        try await apiClient.request(
            path: SocialEndpoints.profilePath(id: id),
            method: .get,
            requiresAuth: true
        )
    }

    func searchProfiles(query: String) async throws -> [SocialProfileResponseDTO] {
        try await apiClient.request(
            path: SocialEndpoints.searchPath,
            method: .get,
            queryItems: [URLQueryItem(name: "q", value: query)],
            requiresAuth: true
        )
    }
}
