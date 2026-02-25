import Foundation

struct TrainingWeek: Identifiable, Equatable, Sendable, Codable {
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
