import Foundation

enum NutritionEndpoints {

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = PaginatedResponseDTO<NutritionResponseDTO>
        var path: String { "/nutrition" }
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
        typealias RequestBody = NutritionUploadRequestDTO
        typealias ResponseBody = NutritionResponseDTO
        let body: NutritionUploadRequestDTO?
        var path: String { "/nutrition" }
        var method: HTTPMethod { .put }

        init(body: NutritionUploadRequestDTO) {
            self.body = body
        }
    }
}
