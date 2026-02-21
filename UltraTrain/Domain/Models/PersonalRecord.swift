import Foundation

enum PersonalRecordType: String, Sendable {
    case longestDistance
    case mostElevation
    case fastestPace
    case longestDuration
    case fastest5K
    case fastest10K
    case fastestHalf
    case fastestMarathon
    case fastest50K
    case fastest100K
}

struct PersonalRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: PersonalRecordType
    let value: Double
    let date: Date
    let runId: UUID
}
