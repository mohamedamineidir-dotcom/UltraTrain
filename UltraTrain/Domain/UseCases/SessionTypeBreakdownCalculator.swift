import Foundation

enum SessionTypeBreakdownCalculator {

    static func compute(from plan: TrainingPlan) -> [SessionTypeStats] {
        let allSessions = plan.weeks.flatMap(\.sessions)
        let activeSessions = allSessions.filter { $0.type != .rest }
        guard !activeSessions.isEmpty else { return [] }

        let totalCount = Double(activeSessions.count)

        var grouped: [SessionType: (count: Int, distance: Double, duration: TimeInterval)] = [:]
        for session in activeSessions {
            var entry = grouped[session.type] ?? (0, 0, 0)
            entry.count += 1
            entry.distance += session.plannedDistanceKm
            entry.duration += session.plannedDuration
            grouped[session.type] = entry
        }

        return grouped.map { type, data in
            SessionTypeStats(
                id: UUID(),
                sessionType: type,
                count: data.count,
                totalDistanceKm: data.distance,
                totalDuration: data.duration,
                percentage: (Double(data.count) / totalCount) * 100
            )
        }
        .sorted { $0.percentage > $1.percentage }
    }
}
