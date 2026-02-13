import Foundation
import os

actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = AppConfiguration.API.baseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func request<Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> Response {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfiguration.appVersion, forHTTPHeaderField: "X-Client-Version")
        request.timeoutInterval = AppConfiguration.API.timeoutInterval

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        Logger.network.debug("Request: \(method.rawValue) \(path)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        Logger.network.debug("Response: \(httpResponse.statusCode) \(path)")

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(Response.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 400...499:
            throw APIError.clientError(statusCode: httpResponse.statusCode)
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
