import Foundation

protocol APIEndpoint: Sendable {
    associatedtype RequestBody: Encodable & Sendable
    associatedtype ResponseBody: Decodable & Sendable

    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: RequestBody? { get }
    var queryItems: [URLQueryItem]? { get }
    var requiresAuth: Bool { get }
}

extension APIEndpoint {
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem]? { nil }
    var requiresAuth: Bool { true }
}

extension APIEndpoint where RequestBody == EmptyRequestBody {
    var body: EmptyRequestBody? { nil }
}
