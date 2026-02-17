import Foundation

enum PersonalRecordType: String, Sendable {
    case longestDistance
    case mostElevation
    case fastestPace
    case longestDuration
}

struct PersonalRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: PersonalRecordType
    let value: Double
    let date: Date
    let runId: UUID
}
