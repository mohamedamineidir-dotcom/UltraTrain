import Vapor

struct PaginatedResponse<T: Content>: Content {
    let items: [T]
    let nextCursor: String?
    let hasMore: Bool
}
