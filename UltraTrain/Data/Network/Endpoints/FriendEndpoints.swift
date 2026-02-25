import Foundation

enum FriendEndpoints {

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [FriendConnectionResponseDTO]
        var path: String { "/friends" }
        var method: HTTPMethod { .get }
    }

    struct FetchPending: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [FriendConnectionResponseDTO]
        var path: String { "/friends/pending" }
        var method: HTTPMethod { .get }
    }

    struct SendRequest: APIEndpoint {
        typealias RequestBody = FriendRequestRequestDTO
        typealias ResponseBody = FriendConnectionResponseDTO
        let body: FriendRequestRequestDTO?
        var path: String { "/friends/request" }
        var method: HTTPMethod { .post }

        init(body: FriendRequestRequestDTO) {
            self.body = body
        }
    }

    struct Accept: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = FriendConnectionResponseDTO
        let connectionId: String
        var path: String { "/friends/\(connectionId)/accept" }
        var method: HTTPMethod { .put }

        init(connectionId: String) {
            self.connectionId = connectionId
        }
    }

    struct Decline: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = FriendConnectionResponseDTO
        let connectionId: String
        var path: String { "/friends/\(connectionId)/decline" }
        var method: HTTPMethod { .put }

        init(connectionId: String) {
            self.connectionId = connectionId
        }
    }

    struct Remove: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        let connectionId: String
        var path: String { "/friends/\(connectionId)" }
        var method: HTTPMethod { .delete }

        init(connectionId: String) {
            self.connectionId = connectionId
        }
    }
}
