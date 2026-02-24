import Foundation

struct IdempotencyInterceptor: Sendable {

    func addKey(_ request: inout URLRequest) {
        guard let method = request.httpMethod,
              ["POST", "PUT", "PATCH"].contains(method) else { return }
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Idempotency-Key")
    }
}
