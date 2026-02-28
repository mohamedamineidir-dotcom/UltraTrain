import Foundation

enum FitnessEndpoints {

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = PaginatedResponseDTO<FitnessSnapshotResponseDTO>
        var path: String { "/fitness-snapshots" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(cursor: String? = nil, limit: Int = 100) {
            var items: [URLQueryItem] = []
            if let cursor {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            items.append(URLQueryItem(name: "limit", value: String(limit)))
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct Upsert: APIEndpoint {
        typealias RequestBody = FitnessSnapshotUploadRequestDTO
        typealias ResponseBody = FitnessSnapshotResponseDTO
        let body: FitnessSnapshotUploadRequestDTO?
        var path: String { "/fitness-snapshots" }
        var method: HTTPMethod { .put }

        init(body: FitnessSnapshotUploadRequestDTO) {
            self.body = body
        }
    }
}
