import Foundation

struct PaginatedResponseDTO<T: Decodable>: Decodable, Sendable where T: Sendable {
    let items: [T]
    let nextCursor: String?
    let hasMore: Bool
}
