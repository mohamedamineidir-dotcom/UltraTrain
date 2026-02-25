import Foundation
import os

struct LoggingInterceptor: Sendable {

    func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "nil"
        let bodySize = request.httpBody?.count ?? 0
        let headers = redactedHeaders(request.allHTTPHeaderFields ?? [:])
        Logger.network.debug(
            "-> \(method) \(url) body=\(bodySize)B headers=[\(headers)]"
        )
    }

    func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval,
        url: URL?
    ) {
        let path = url?.path ?? "unknown"
        let statusCode = response.statusCode
        let bodySize = data.count
        let durationMs = Int(duration * 1000)

        switch statusCode {
        case 200...299:
            Logger.network.debug(
                "<- \(statusCode) \(path) \(bodySize)B \(durationMs)ms"
            )
        case 400...499:
            Logger.network.warning(
                "<- \(statusCode) \(path) \(bodySize)B \(durationMs)ms"
            )
        default:
            Logger.network.error(
                "<- \(statusCode) \(path) \(bodySize)B \(durationMs)ms"
            )
        }
    }

    // MARK: - Private

    private func redactedHeaders(_ headers: [String: String]) -> String {
        var safe = headers
        for key in ["Authorization", "X-Signature"] {
            if safe[key] != nil {
                safe[key] = "[REDACTED]"
            }
        }
        return safe.map { "\($0.key): \($0.value)" }
            .sorted()
            .joined(separator: ", ")
    }
}
