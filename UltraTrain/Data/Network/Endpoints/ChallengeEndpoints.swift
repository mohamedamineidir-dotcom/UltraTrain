import Foundation

enum ChallengeEndpoints {

    struct Create: APIEndpoint {
        typealias RequestBody = CreateChallengeRequestDTO
        typealias ResponseBody = GroupChallengeResponseDTO
        let body: CreateChallengeRequestDTO?
        var path: String { "/challenges" }
        var method: HTTPMethod { .post }

        init(body: CreateChallengeRequestDTO) {
            self.body = body
        }
    }

    struct FetchAll: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = [GroupChallengeResponseDTO]
        var path: String { "/challenges" }
        var method: HTTPMethod { .get }
        let queryItems: [URLQueryItem]?

        init(status: String? = nil) {
            if let status {
                self.queryItems = [URLQueryItem(name: "status", value: status)]
            } else {
                self.queryItems = nil
            }
        }
    }

    struct FetchOne: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = GroupChallengeResponseDTO
        let id: String
        var path: String { "/challenges/\(id)" }
        var method: HTTPMethod { .get }

        init(id: String) {
            self.id = id
        }
    }

    struct Join: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = GroupChallengeResponseDTO
        let id: String
        var path: String { "/challenges/\(id)/join" }
        var method: HTTPMethod { .post }

        init(id: String) {
            self.id = id
        }
    }

    struct Leave: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = EmptyResponseBody
        let id: String
        var path: String { "/challenges/\(id)/leave" }
        var method: HTTPMethod { .post }

        init(id: String) {
            self.id = id
        }
    }

    struct UpdateProgress: APIEndpoint {
        typealias RequestBody = UpdateProgressRequestDTO
        typealias ResponseBody = ChallengeParticipantResponseDTO
        let body: UpdateProgressRequestDTO?
        let challengeId: String
        var path: String { "/challenges/\(challengeId)/progress" }
        var method: HTTPMethod { .put }

        init(challengeId: String, body: UpdateProgressRequestDTO) {
            self.challengeId = challengeId
            self.body = body
        }
    }
}
