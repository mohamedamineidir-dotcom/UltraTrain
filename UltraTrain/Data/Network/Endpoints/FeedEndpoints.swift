import Foundation

enum FeedEndpoints {

    struct Fetch: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [ActivityFeedItemResponseDTO]
        var path: String { "/feed" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(limit: Int = 50) {
            self.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        }
    }

    struct Publish: APIEndpoint {
        typealias RequestBody = PublishActivityRequestDTO
        typealias ResponseBody = ActivityFeedItemResponseDTO
        let body: PublishActivityRequestDTO?
        var path: String { "/feed" }
        var method: HTTPMethod { .post }

        init(body: PublishActivityRequestDTO) {
            self.body = body
        }
    }

    struct ToggleLike: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = LikeResponseDTO
        let itemId: String
        var path: String { "/feed/\(itemId)/like" }
        var method: HTTPMethod { .post }

        init(itemId: String) {
            self.itemId = itemId
        }
    }
}
