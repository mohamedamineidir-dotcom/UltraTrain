import Foundation

struct RaceSnapshot: Codable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let priority: RacePriority
}

struct TrainingPlan: Identifiable, Equatable, Sendable {
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

struct TrainingWeek: Identifiable, Equatable, Sendable {
    let id: UUID
    var weekNumber: Int
    var startDate: Date
    var endDate: Date
    var phase: TrainingPhase
    var sessions: [TrainingSession]
    var isRecoveryWeek: Bool
    var targetVolumeKm: Double
    var targetElevationGainM: Double

    func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return day >= start && day <= end
    }

    var containsToday: Bool { contains(date: .now) }
}

enum TrainingPhase: String, CaseIterable, Sendable {
    case base
    case build
    case peak
    case taper
    case recovery
    case race
}

struct TrainingSession: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var type: SessionType
    var plannedDistanceKm: Double
    var plannedElevationGainM: Double
    var plannedDuration: TimeInterval
    var intensity: Intensity
    var description: String
    var nutritionNotes: String?
    var isCompleted: Bool
    var isSkipped: Bool
    var linkedRunId: UUID?
    var targetHeartRateZone: Int? = nil

    var isGutTrainingRecommended: Bool {
        (type == .longRun || type == .backToBack) && plannedDuration >= 7200
    }
}

enum SessionType: String, CaseIterable, Sendable {
    case longRun
    case tempo
    case intervals
    case verticalGain
    case backToBack
    case recovery
    case crossTraining
    case rest
}

enum Intensity: String, CaseIterable, Sendable {
    case easy
    case moderate
    case hard
    case maxEffort
}
