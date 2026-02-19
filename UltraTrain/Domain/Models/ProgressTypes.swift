import Foundation

struct WeeklyVolume: Identifiable, Equatable {
    let id: Date
    var weekStartDate: Date
    var distanceKm: Double
    var elevationGainM: Double
    var duration: TimeInterval
    var runCount: Int

    init(weekStartDate: Date, distanceKm: Double = 0, elevationGainM: Double = 0, duration: TimeInterval = 0, runCount: Int = 0) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.duration = duration
        self.runCount = runCount
    }
}

struct WeeklyAdherence: Identifiable, Equatable {
    let id: Date
    var weekStartDate: Date
    var weekNumber: Int
    var completed: Int
    var total: Int
    var percent: Double

    init(weekStartDate: Date, weekNumber: Int, completed: Int, total: Int) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.weekNumber = weekNumber
        self.completed = completed
        self.total = total
        self.percent = total > 0 ? Double(completed) / Double(total) * 100 : 0
    }
}

enum FormStatus: Equatable {
    case raceReady
    case fresh
    case building
    case fatigued
    case noData
}
