import Foundation

enum SharedRunEndpoints {
    static let sharedRunsPath = "/shared-runs"
    static let mySharedRunsPath = "/shared-runs/mine"

    static func sharedRunPath(id: String) -> String {
        "/shared-runs/\(id)"
    }
}
