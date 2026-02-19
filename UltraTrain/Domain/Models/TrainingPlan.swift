import Foundation

struct TrainingPlan: Identifiable, Equatable, Sendable {
    let id: UUID
    var athleteId: UUID
    var targetRaceId: UUID
    var createdAt: Date
    var weeks: [TrainingWeek]
    var intermediateRaceIds: [UUID]

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

    var containsToday: Bool {
        let now = Date.now
        return now >= startDate && now <= endDate
    }
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
