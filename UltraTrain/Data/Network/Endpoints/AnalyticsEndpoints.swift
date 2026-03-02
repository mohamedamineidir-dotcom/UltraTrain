import Foundation

enum AnalyticsEndpoints {

    struct TrackBatch: APIEndpoint {
        typealias RequestBody = AnalyticsPayload
        typealias ResponseBody = EmptyResponseBody
        let body: AnalyticsPayload?
        var path: String { "analytics/events" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { false }

        init(payload: AnalyticsPayload) {
            self.body = payload
        }
    }
}
