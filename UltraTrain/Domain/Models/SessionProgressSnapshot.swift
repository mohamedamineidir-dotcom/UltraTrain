import Foundation

struct SessionProgressSnapshot: Sendable {
    let key: String
    let isCompleted: Bool
    let isSkipped: Bool
    let linkedRunId: UUID?
}
