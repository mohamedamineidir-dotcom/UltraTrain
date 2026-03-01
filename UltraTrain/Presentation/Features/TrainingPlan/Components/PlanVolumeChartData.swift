import Foundation

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
}

enum PlanVolumeChartData {
    static func extract(from weeks: [TrainingWeek]) -> [WeekChartDataPoint] {
        weeks.map { week in
            let activeSessions = week.sessions.filter { $0.type != .rest && !$0.isSkipped }
            let completedSessions = activeSessions.filter(\.isCompleted)

            return WeekChartDataPoint(
                id: week.weekNumber,
                weekNumber: week.weekNumber,
                startDate: week.startDate,
                phase: week.phase,
                plannedDistanceKm: week.targetVolumeKm,
                completedDistanceKm: completedSessions.reduce(0) { $0 + $1.plannedDistanceKm },
                plannedDurationSeconds: activeSessions.reduce(0) { $0 + $1.plannedDuration },
                completedDurationSeconds: completedSessions.reduce(0) { $0 + $1.plannedDuration },
                plannedElevationM: week.targetElevationGainM,
                completedElevationM: completedSessions.reduce(0) { $0 + $1.plannedElevationGainM },
                isCurrentWeek: week.containsToday
            )
        }
    }
}
