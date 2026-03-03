import Vapor

actor RateLimitStore {
    private var requests: [String: [Date]] = [:]
    private let maxRequests: Int
    private let windowSeconds: TimeInterval
    private var lastCleanup: Date = Date()
    private let cleanupInterval: TimeInterval = 300 // Prune stale entries every 5 minutes

    init(maxRequests: Int, windowSeconds: TimeInterval) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    func shouldAllow(key: String) -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-windowSeconds)

        // Periodically prune all stale entries to prevent unbounded memory growth
        if now.timeIntervalSince(lastCleanup) > cleanupInterval {
            requests = requests.compactMapValues { timestamps in
                let active = timestamps.filter { $0 >= cutoff }
                return active.isEmpty ? nil : active
            }
            lastCleanup = now
        }

        var timestamps = requests[key, default: []]
        timestamps.removeAll { $0 < cutoff }
        timestamps.append(now)
        requests[key] = timestamps

        return timestamps.count <= maxRequests
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    private let store: RateLimitStore

    init(maxRequests: Int, windowSeconds: TimeInterval = 60) {
        self.store = RateLimitStore(maxRequests: maxRequests, windowSeconds: windowSeconds)
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let key = request.headers.first(name: "X-Forwarded-For")?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
            ?? request.peerAddress?.description
            ?? "unknown"

        guard await store.shouldAllow(key: key) else {
            throw Abort(.tooManyRequests, reason: "Rate limit exceeded. Try again later.")
        }

        return try await next.respond(to: request)
    }
}
