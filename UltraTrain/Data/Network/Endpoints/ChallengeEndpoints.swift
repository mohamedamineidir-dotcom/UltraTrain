import Foundation

enum ChallengeEndpoints {
    static let challengesPath = "/challenges"

    static func challengePath(id: String) -> String {
        "/challenges/\(id)"
    }

    static func joinPath(id: String) -> String {
        "/challenges/\(id)/join"
    }

    static func leavePath(id: String) -> String {
        "/challenges/\(id)/leave"
    }

    static func progressPath(id: String) -> String {
        "/challenges/\(id)/progress"
    }
}
