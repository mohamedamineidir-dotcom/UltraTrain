import Foundation

struct RetryInterceptor: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval

    init(maxAttempts: Int = 3, baseDelay: TimeInterval = 1.0) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
    }

    func shouldRetry(statusCode: Int, attempt: Int) -> Bool {
        guard statusCode >= 500 || statusCode == 0 else { return false }
        return attempt < maxAttempts - 1
    }

    func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0.75...1.25)
        return exponential * jitter
    }
}
