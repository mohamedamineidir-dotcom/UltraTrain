import Vapor
import Crypto

struct HMACVerificationMiddleware: AsyncMiddleware {
    private let secret: String
    private let maxTimestampAge: TimeInterval

    init(secret: String, maxTimestampAge: TimeInterval = 300) {
        self.secret = secret
        self.maxTimestampAge = maxTimestampAge
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let signatureHeader = request.headers.first(name: "X-Signature"),
              let timestampHeader = request.headers.first(name: "X-Timestamp") else {
            throw Abort(.unauthorized, reason: "Missing request signature")
        }

        // Validate timestamp freshness (prevent replay attacks)
        let formatter = ISO8601DateFormatter()
        guard let timestamp = formatter.date(from: timestampHeader) else {
            throw Abort(.unauthorized, reason: "Invalid timestamp format")
        }

        let age = abs(Date().timeIntervalSince(timestamp))
        guard age <= maxTimestampAge else {
            throw Abort(.unauthorized, reason: "Request timestamp expired")
        }

        // Reconstruct payload: timestamp + body (matches iOS RequestSigningInterceptor).
        // Must explicitly collect the body rather than reading `request.body.data`
        // directly: Vapor only pre-populates `.data` when the whole body arrives in a
        // single network read matching Content-Length. Any body split across more than
        // one read (increasingly likely as size grows — a few KB is enough to trigger
        // this depending on network conditions) is left in `.stream` state, where
        // `.data` silently returns nil and this would sign an empty body instead of the
        // real one, never matching the client's signature.
        let bodyBuffer = try await request.body.collect(max: 10 * 1024 * 1024).get()
        let body = bodyBuffer.map { Data(buffer: $0) } ?? Data()
        let payload = Data(timestampHeader.utf8) + body

        // Compute expected HMAC-SHA256
        let key = SymmetricKey(data: Data(secret.utf8))
        let expectedMAC = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let expectedSignature = Data(expectedMAC).base64EncodedString()

        // Compare signatures
        guard signatureHeader == expectedSignature else {
            request.logger.warning("HMAC signature mismatch for \(request.method) \(request.url.path)")
            throw Abort(.unauthorized, reason: "Invalid request signature")
        }

        return try await next.respond(to: request)
    }
}
