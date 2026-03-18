import Foundation

enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
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
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Invalid email or password."
        case .conflict(let reason):
            return reason ?? "Conflict. Please try again."
        case .clientError(_, let reason):
            return reason ?? "Request failed."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .decodingError:
            return "Failed to process server response."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let code):
            return "Unexpected error (\(code))."
        }
    }
}
