import Foundation

enum CrashEndpoints {

    struct Upload: APIEndpoint {
        typealias RequestBody = CrashReport
        typealias ResponseBody = EmptyResponseBody
        let body: CrashReport?
        var path: String { "crashes" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(body: CrashReport) {
            self.body = body
        }
    }
}
