import Foundation
import os

actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let authInterceptor: AuthInterceptor?
    private let retryInterceptor: RetryInterceptor
    private let signingInterceptor: RequestSigningInterceptor?
    private let idempotencyInterceptor: IdempotencyInterceptor

    private static let pinnedSession: URLSession = {
        let delegate = CertificatePinningDelegate()
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }()

    init(
        baseURL: URL = AppConfiguration.API.baseURL,
        session: URLSession? = nil,
        authInterceptor: AuthInterceptor? = nil,
        retryInterceptor: RetryInterceptor = RetryInterceptor(),
        signingInterceptor: RequestSigningInterceptor? = nil,
        idempotencyInterceptor: IdempotencyInterceptor = IdempotencyInterceptor()
    ) {
        self.baseURL = baseURL
        self.session = session ?? APIClient.pinnedSession
        self.authInterceptor = authInterceptor
        self.retryInterceptor = retryInterceptor
        self.signingInterceptor = signingInterceptor
        self.idempotencyInterceptor = idempotencyInterceptor

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    private var inFlightGETs: [InFlightRequestKey: Task<(Data, HTTPURLResponse), Error>] = [:]

    func request<Response: Decodable>(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> Response {
        let bodyData = try body.map { try encoder.encode($0) }

        let (data, httpResponse): (Data, HTTPURLResponse)
        if method == .get {
            (data, httpResponse) = try await deduplicatedGET(
                path: path,
                bodyData: bodyData,
                queryItems: queryItems,
                requiresAuth: requiresAuth
            )
        } else {
            (data, httpResponse) = try await performNetworkCall(
                path: path,
                method: method,
                bodyData: bodyData,
                queryItems: queryItems,
                requiresAuth: requiresAuth
            )
        }

        return try handleResponse(data: data, statusCode: httpResponse.statusCode)
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

    // MARK: - Deduplication

    private func deduplicatedGET(
        path: String,
        bodyData: Data?,
        queryItems: [URLQueryItem]?,
        requiresAuth: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        let key = InFlightRequestKey(
            method: "GET",
            path: path,
            queryItems: queryItems,
            bodyData: bodyData
        )

        if let existingTask = inFlightGETs[key] {
            return try await existingTask.value
        }

        let task = Task<(Data, HTTPURLResponse), Error> {
            try await performNetworkCall(
                path: path,
                method: .get,
                bodyData: bodyData,
                queryItems: queryItems,
                requiresAuth: requiresAuth
            )
        }
        inFlightGETs[key] = task

        do {
            let result = try await task.value
            inFlightGETs.removeValue(forKey: key)
            return result
        } catch {
            inFlightGETs.removeValue(forKey: key)
            throw error
        }
    }

    // MARK: - Network Call

    private func performNetworkCall(
        path: String,
        method: HTTPMethod,
        bodyData: Data?,
        queryItems: [URLQueryItem]?,
        requiresAuth: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        var urlRequest = try buildRequest(
            path: path,
            method: method,
            bodyData: bodyData,
            queryItems: queryItems
        )

        idempotencyInterceptor.addKey(&urlRequest)

        if requiresAuth, let interceptor = authInterceptor {
            let token = try await interceptor.validToken()
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if requiresAuth {
            signingInterceptor?.sign(&urlRequest)
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

                if httpResponse.statusCode == 401, requiresAuth, let interceptor = authInterceptor {
                    let newToken = try await interceptor.handleUnauthorized()
                    urlRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    let (retryData, retryResponse) = try await session.data(for: urlRequest)
                    guard let retryHttp = retryResponse as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    return (retryData, retryHttp)
                }

                return (data, httpResponse)

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

    // MARK: - Private

    private func buildRequest(
        path: String,
        method: HTTPMethod,
        bodyData: Data?,
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

        if let bodyData {
            request.httpBody = bodyData
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
        case 409:
            throw APIError.conflict
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
