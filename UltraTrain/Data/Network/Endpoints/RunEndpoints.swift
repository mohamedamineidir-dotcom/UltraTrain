import Foundation

enum RunEndpoints {
    static let runsPath = "/runs"

    static func runPath(id: String) -> String {
        "/runs/\(id)"
    }
}
