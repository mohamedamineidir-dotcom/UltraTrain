import Foundation
import os

actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let authInterceptor: AuthInterceptor?
    private let retryInterceptor: RetryInterceptor

    init(
        baseURL: URL = AppConfiguration.API.baseURL,
        session: URLSession = .shared,
        authInterceptor: AuthInterceptor? = nil,
        retryInterceptor: RetryInterceptor = RetryInterceptor()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authInterceptor = authInterceptor
        self.retryInterceptor = retryInterceptor

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
        var urlRequest = try buildRequest(
            path: path,
            method: method,
            body: body,
            queryItems: queryItems
        )

        if requiresAuth, let interceptor = authInterceptor {
            let token = try await interceptor.validToken()
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        Logger.network.debug("Request: \(method.rawValue) \(path)")

        var lastError: Error = APIError.unknown(statusCode: -1)

        for attempt in 0..<retryInterceptor.maxAttempts {
            do {
                let (data, response) = try await session.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                Logger.network.debug("Response: \(httpResponse.statusCode) \(path)")

                // Handle 401 — attempt token refresh once
                if httpResponse.statusCode == 401, requiresAuth, let interceptor = authInterceptor {
                    let newToken = try await interceptor.handleUnauthorized()
                    urlRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await session.data(for: urlRequest)
                    guard let retryHttp = retryResponse as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    return try handleResponse(data: retryData, statusCode: retryHttp.statusCode)
                }

                return try handleResponse(data: data, statusCode: httpResponse.statusCode)

            } catch let error as APIError {
                if case .serverError = error,
                   retryInterceptor.shouldRetry(statusCode: 500, attempt: attempt) {
                    let delay = retryInterceptor.delay(for: attempt)
                    Logger.network.info("Retrying \(path) in \(delay)s (attempt \(attempt + 1))")
                    try await Task.sleep(for: .seconds(delay))
                    lastError = error
                    continue
                }
                throw error
            } catch {
                if (error as NSError).code == NSURLErrorTimedOut,
                   retryInterceptor.shouldRetry(statusCode: 0, attempt: attempt) {
                    let delay = retryInterceptor.delay(for: attempt)
                    try await Task.sleep(for: .seconds(delay))
                    lastError = error
                    continue
                }
                throw error
            }
        }

        throw lastError
    }

    func requestVoid(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) async throws {
        let _: EmptyResponseBody = try await request(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
    }

    // MARK: - Private

    private func buildRequest(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: true
        )
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

        return request
    }

    private func handleResponse<T: Decodable>(data: Data, statusCode: Int) throws -> T {
        switch statusCode {
        case 200...299:
            if T.self == EmptyResponseBody.self {
                return EmptyResponseBody() as! T
            }
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 400...499:
            throw APIError.clientError(statusCode: statusCode)
        case 500...599:
            throw APIError.serverError(statusCode: statusCode)
        default:
            throw APIError.unknown(statusCode: statusCode)
        }
    }
}

struct EmptyResponseBody: Decodable {
    init() {}
    init(from decoder: Decoder) throws {}
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
