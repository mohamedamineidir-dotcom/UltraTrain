import Foundation

enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    /// 401 on a request that doesn't carry a session token (login,
    /// register, etc.) — the credentials themselves were rejected.
    case unauthorized
    /// 401 on a request that DID carry a session token, and a refresh
    /// attempt still didn't produce one the server accepts — the user's
    /// session is genuinely gone, not a credentials problem. Kept
    /// distinct from `.unauthorized` so this can't surface a
    /// login-flavored message ("Invalid email or password") on a screen
    /// that has nothing to do with logging in, e.g. food-photo analysis
    /// failing because a slow upload crossed the access token's expiry.
    case sessionExpired
    case conflict(reason: String?)
    case clientError(statusCode: Int, reason: String?)
    case serverError(statusCode: Int)
    case decodingError
    case networkError(message: String)
    case unknown(statusCode: Int)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "apiError.invalidURL", defaultValue: "Invalid URL.")
        case .invalidResponse:
            return String(localized: "apiError.invalidResponse", defaultValue: "Invalid server response.")
        case .unauthorized:
            return String(localized: "apiError.unauthorized", defaultValue: "Invalid email or password.")
        case .sessionExpired:
            return String(localized: "apiError.sessionExpired", defaultValue: "Your session has expired. Please sign in again.")
        case .conflict(let reason):
            return reason ?? String(localized: "apiError.conflict", defaultValue: "Conflict. Please try again.")
        case .clientError(_, let reason):
            return reason ?? String(localized: "apiError.clientError", defaultValue: "Request failed.")
        case .serverError(let code):
            return String(format: String(localized: "apiError.serverError", defaultValue: "Server error (%d). Please try again."), code)
        case .decodingError:
            return String(localized: "apiError.decodingError", defaultValue: "Failed to process server response.")
        case .networkError(let message):
            return String(format: String(localized: "apiError.networkError", defaultValue: "Network error: %@"), message)
        case .unknown(let code):
            return String(format: String(localized: "apiError.unknown", defaultValue: "Unexpected error (%d)."), code)
        }
    }
}
