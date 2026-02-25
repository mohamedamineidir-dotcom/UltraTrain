import Foundation

final class RemoteActivityFeedDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFeed(limit: Int = 50) async throws -> [ActivityFeedItemResponseDTO] {
        try await apiClient.send(FeedEndpoints.Fetch(limit: limit))
    }

    func publishActivity(_ dto: PublishActivityRequestDTO) async throws -> ActivityFeedItemResponseDTO {
        try await apiClient.send(FeedEndpoints.Publish(body: dto))
    }

    func toggleLike(itemId: String) async throws -> LikeResponseDTO {
        try await apiClient.send(FeedEndpoints.ToggleLike(itemId: itemId))
    }
}
