import Foundation

struct PersonalRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: PersonalRecordType
    let value: Double
    let date: Date
    let runId: UUID
}
