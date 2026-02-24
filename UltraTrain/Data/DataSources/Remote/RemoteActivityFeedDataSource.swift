import Foundation

final class RemoteActivityFeedDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFeed(limit: Int = 50) async throws -> [ActivityFeedItemResponseDTO] {
        try await apiClient.request(
            path: FeedEndpoints.feedPath,
            method: .get,
            queryItems: [URLQueryItem(name: "limit", value: String(limit))],
            requiresAuth: true
        )
    }

    func publishActivity(_ dto: PublishActivityRequestDTO) async throws -> ActivityFeedItemResponseDTO {
        try await apiClient.request(
            path: FeedEndpoints.feedPath,
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }

    func toggleLike(itemId: String) async throws -> LikeResponseDTO {
        try await apiClient.request(
            path: FeedEndpoints.likePath(itemId: itemId),
            method: .post,
            requiresAuth: true
        )
    }
}
