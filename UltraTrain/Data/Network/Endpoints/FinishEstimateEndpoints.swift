import Foundation

enum FinishEstimateEndpoints {

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = PaginatedResponseDTO<FinishEstimateResponseDTO>
        var path: String { "/finish-estimates" }
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
        typealias RequestBody = FinishEstimateUploadRequestDTO
        typealias ResponseBody = FinishEstimateResponseDTO
        let body: FinishEstimateUploadRequestDTO?
        var path: String { "/finish-estimates" }
        var method: HTTPMethod { .put }

        init(body: FinishEstimateUploadRequestDTO) {
            self.body = body
        }
    }
}
