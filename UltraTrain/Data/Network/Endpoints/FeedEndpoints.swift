import Foundation

enum FeedEndpoints {
    static let feedPath = "/feed"

    static func likePath(itemId: String) -> String {
        "/feed/\(itemId)/like"
    }
}
