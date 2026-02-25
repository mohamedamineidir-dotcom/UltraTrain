import Foundation

enum SocialEndpoints {

    struct FetchMyProfile: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = SocialProfileResponseDTO
        var path: String { "/social/profile" }
        var method: HTTPMethod { .get }
    }

    struct UpdateProfile: APIEndpoint {
        typealias RequestBody = SocialProfileUpdateRequestDTO
        typealias ResponseBody = SocialProfileResponseDTO
        let body: SocialProfileUpdateRequestDTO?
        var path: String { "/social/profile" }
        var method: HTTPMethod { .put }

        init(body: SocialProfileUpdateRequestDTO) {
            self.body = body
        }
    }

    struct FetchProfile: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = SocialProfileResponseDTO
        let id: String
        var path: String { "/social/profile/\(id)" }
        var method: HTTPMethod { .get }

        init(id: String) {
            self.id = id
        }
    }

    struct Search: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [SocialProfileResponseDTO]
        var path: String { "/social/search" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(query: String) {
            self.queryItems = [URLQueryItem(name: "q", value: query)]
        }
    }
}
