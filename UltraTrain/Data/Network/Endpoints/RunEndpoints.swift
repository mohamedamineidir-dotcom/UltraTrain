import Foundation

enum RunEndpoints {

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = PaginatedResponseDTO<RunResponseDTO>
        var path: String { "/runs" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(since: Date? = nil, cursor: String? = nil, limit: Int = 20) {
            let formatter = ISO8601DateFormatter()
            var items: [URLQueryItem] = []
            if let since {
                items.append(URLQueryItem(name: "since", value: formatter.string(from: since)))
            }
            if let cursor {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            items.append(URLQueryItem(name: "limit", value: String(limit)))
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct Upload: APIEndpoint {
        typealias RequestBody = RunUploadRequestDTO
        typealias ResponseBody = RunResponseDTO
        let body: RunUploadRequestDTO?
        var path: String { "/runs" }
        var method: HTTPMethod { .post }

        init(body: RunUploadRequestDTO) {
            self.body = body
        }
    }

    struct Update: APIEndpoint {
        typealias RequestBody = RunUploadRequestDTO
        typealias ResponseBody = RunResponseDTO
        let body: RunUploadRequestDTO?
        let id: String
        var path: String { "/runs/\(id)" }
        var method: HTTPMethod { .put }

        init(id: UUID, body: RunUploadRequestDTO) {
            self.id = id.uuidString
            self.body = body
        }
    }

    struct Delete: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        let id: String
        var path: String { "/runs/\(id)" }
        var method: HTTPMethod { .delete }

        init(id: UUID) {
            self.id = id.uuidString
        }
    }
}
