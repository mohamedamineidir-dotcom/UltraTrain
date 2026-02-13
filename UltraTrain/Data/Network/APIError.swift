import Foundation

enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case clientError(statusCode: Int)
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
            return "Unauthorized. Please sign in again."
        case .clientError(let code):
            return "Request failed with status \(code)."
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
