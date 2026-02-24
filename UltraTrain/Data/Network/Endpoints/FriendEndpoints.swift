import Foundation

enum FriendEndpoints {
    static let friendsPath = "/friends"
    static let pendingPath = "/friends/pending"
    static let requestPath = "/friends/request"

    static func acceptPath(id: String) -> String {
        "/friends/\(id)/accept"
    }

    static func declinePath(id: String) -> String {
        "/friends/\(id)/decline"
    }

    static func friendPath(id: String) -> String {
        "/friends/\(id)"
    }
}
