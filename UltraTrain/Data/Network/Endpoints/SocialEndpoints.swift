import Foundation

enum SocialEndpoints {
    static let profilePath = "/social/profile"

    static func profilePath(id: String) -> String {
        "/social/profile/\(id)"
    }

    static let searchPath = "/social/search"
}
