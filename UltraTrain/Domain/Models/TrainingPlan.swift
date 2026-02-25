import Foundation

struct TrainingPlan: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var athleteId: UUID
    var targetRaceId: UUID
    var createdAt: Date
    var weeks: [TrainingWeek]
    var intermediateRaceIds: [UUID]
    var intermediateRaceSnapshots: [RaceSnapshot]

    var totalWeeks: Int { weeks.count }
    var currentWeekIndex: Int? {
        weeks.firstIndex { $0.containsToday }
    }
}
