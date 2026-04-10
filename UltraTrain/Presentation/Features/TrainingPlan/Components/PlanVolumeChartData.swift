import Foundation

struct SessionTypeSlice: Identifiable {
    let id = UUID()
    let type: SessionType
    let durationSeconds: TimeInterval
    let distanceKm: Double
    let elevationM: Double
}

struct WeekChartDataPoint: Identifiable {
    let id: Int
    let weekNumber: Int
    let startDate: Date
    let phase: TrainingPhase
    let plannedDistanceKm: Double
    let completedDistanceKm: Double
    let plannedDurationSeconds: TimeInterval
    let completedDurationSeconds: TimeInterval
    let plannedElevationM: Double
    let completedElevationM: Double
    let isCurrentWeek: Bool
    let isRecoveryWeek: Bool
    let completedByType: [SessionTypeSlice]
}

enum PlanVolumeChartData {
    static func extract(from weeks: [TrainingWeek]) -> [WeekChartDataPoint] {
        weeks.map { week in
            // Exclude rest and S&C from running volume metrics
            let activeSessions = week.sessions.filter { $0.type != .rest && $0.type != .strengthConditioning && !$0.isSkipped }
            let completedSessions = activeSessions.filter(\.isCompleted)

            let typeGroups = Dictionary(grouping: completedSessions, by: \.type)
            let slices = typeGroups.map { type, sessions in
                SessionTypeSlice(
                    type: type,
                    durationSeconds: sessions.reduce(0) { $0 + ($1.actualDurationSeconds ?? $1.plannedDuration) },
                    distanceKm: sessions.reduce(0) { $0 + ($1.actualDistanceKm ?? $1.plannedDistanceKm) },
                    elevationM: sessions.reduce(0) { $0 + ($1.actualElevationGainM ?? $1.plannedElevationGainM) }
                )
            }.sorted { $0.type.stackOrder < $1.type.stackOrder }

            return WeekChartDataPoint(
                id: week.weekNumber,
                weekNumber: week.weekNumber,
                startDate: week.startDate,
                phase: week.phase,
                plannedDistanceKm: week.targetVolumeKm,
                completedDistanceKm: completedSessions.reduce(0) { $0 + ($1.actualDistanceKm ?? $1.plannedDistanceKm) },
                plannedDurationSeconds: week.targetDurationSeconds > 0
                    ? week.targetDurationSeconds
                    : activeSessions.reduce(0) { $0 + $1.plannedDuration },
                completedDurationSeconds: completedSessions.reduce(0) { $0 + ($1.actualDurationSeconds ?? $1.plannedDuration) },
                plannedElevationM: week.targetElevationGainM,
                completedElevationM: completedSessions.reduce(0) { $0 + ($1.actualElevationGainM ?? $1.plannedElevationGainM) },
                isCurrentWeek: week.containsToday,
                isRecoveryWeek: week.isRecoveryWeek,
                completedByType: slices
            )
        }
    }
}

extension SessionType {
    var stackOrder: Int {
        switch self {
        case .recovery:      0
        case .crossTraining: 1
        case .longRun:       2
        case .backToBack:    3
        case .tempo:         4
        case .verticalGain:  5
        case .intervals:     6
        case .rest:                  7
        case .strengthConditioning:  8
        case .race:                  9
        }
    }
}
