import Vapor

struct RequestLoggingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let start = Date()
        let method = request.method.rawValue
        let path = request.url.path

        do {
            let response = try await next.respond(to: request)
            let duration = Date().timeIntervalSince(start) * 1000
            request.logger.info("\(method) \(path) \(response.status.code) \(String(format: "%.1f", duration))ms")
            return response
        } catch {
            let duration = Date().timeIntervalSince(start) * 1000
            let status = (error as? AbortError)?.status.code ?? 500
            request.logger.warning("\(method) \(path) \(status) \(String(format: "%.1f", duration))ms")
            throw error
        }
    }
}
