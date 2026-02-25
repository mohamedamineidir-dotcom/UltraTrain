import Foundation

enum SharedRunEndpoints {

    struct Share: APIEndpoint {
        typealias RequestBody = ShareRunRequestDTO
        typealias ResponseBody = SharedRunResponseDTO
        let body: ShareRunRequestDTO?
        var path: String { "/shared-runs" }
        var method: HTTPMethod { .post }

        init(body: ShareRunRequestDTO) {
            self.body = body
        }
    }

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [SharedRunResponseDTO]
        var path: String { "/shared-runs" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(limit: Int = 20) {
            self.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        }
    }

    struct FetchMine: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [SharedRunResponseDTO]
        var path: String { "/shared-runs/mine" }
        var method: HTTPMethod { .get }
    }

    struct Revoke: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        let id: String
        var path: String { "/shared-runs/\(id)" }
        var method: HTTPMethod { .delete }

        init(id: String) {
            self.id = id
        }
    }
}
