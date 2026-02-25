import Foundation

struct EmptyRequestBody: Encodable, Sendable {
    static let value = EmptyRequestBody()
}

struct EmptyResponseBody: Decodable, Sendable {
    init() {}
    init(from decoder: Decoder) throws {}
}
