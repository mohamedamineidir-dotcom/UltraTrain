import Foundation

enum AthleteEndpoints {

    struct Fetch: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = AthleteDTO
        var path: String { "/athlete" }
        var method: HTTPMethod { .get }
    }

    struct Update: APIEndpoint {
        typealias RequestBody = AthleteDTO
        typealias ResponseBody = AthleteDTO
        let body: AthleteDTO?
        var path: String { "/athlete" }
        var method: HTTPMethod { .put }

        init(body: AthleteDTO) {
            self.body = body
        }
    }
}
