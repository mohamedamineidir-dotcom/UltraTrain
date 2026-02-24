import Foundation

struct InFlightRequestKey: Hashable, Sendable {
    let method: String
    let path: String
    let queryHash: Int
    let bodyHash: Int

    init(method: String, path: String, queryItems: [URLQueryItem]?, bodyData: Data?) {
        self.method = method
        self.path = path
        self.queryHash = queryItems?.sorted(by: { $0.name < $1.name }).hashValue ?? 0
        self.bodyHash = bodyData?.hashValue ?? 0
    }
}
