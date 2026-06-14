import Foundation

enum StravaEndpoints {

    /// Exchanges a Strava authorization code for tokens. The backend holds the
    /// client secret and performs the exchange. Auth-required.
    struct Exchange: APIEndpoint {
        typealias RequestBody = StravaExchangeRequestDTO
        typealias ResponseBody = StravaTokenDTO
        let body: StravaExchangeRequestDTO?
        var path: String { "/integrations/strava/exchange" }
        var method: HTTPMethod { .post }

        init(code: String) {
            self.body = StravaExchangeRequestDTO(code: code)
        }
    }

    /// Refreshes an expired Strava access token via the backend.
    struct Refresh: APIEndpoint {
        typealias RequestBody = StravaRefreshRequestDTO
        typealias ResponseBody = StravaTokenDTO
        let body: StravaRefreshRequestDTO?
        var path: String { "/integrations/strava/refresh" }
        var method: HTTPMethod { .post }

        init(refreshToken: String) {
            self.body = StravaRefreshRequestDTO(refreshToken: refreshToken)
        }
    }
}
