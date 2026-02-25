import Foundation

enum RaceEndpoints {

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = PaginatedResponseDTO<RaceResponseDTO>
        var path: String { "/races" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(cursor: String? = nil, limit: Int = 20) {
            var items: [URLQueryItem] = []
            if let cursor {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            items.append(URLQueryItem(name: "limit", value: String(limit)))
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct Upsert: APIEndpoint {
        typealias RequestBody = RaceUploadRequestDTO
        typealias ResponseBody = RaceResponseDTO
        let body: RaceUploadRequestDTO?
        var path: String { "/races" }
        var method: HTTPMethod { .put }

        init(body: RaceUploadRequestDTO) {
            self.body = body
        }
    }

    struct Delete: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        let id: String
        var path: String { "/races/\(id)" }
        var method: HTTPMethod { .delete }

        init(id: String) {
            self.id = id
        }
    }
}
