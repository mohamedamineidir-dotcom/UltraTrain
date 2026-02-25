import Foundation

struct WeeklyLoadData: Identifiable, Equatable, Sendable {
    let id: Date
    var weekStartDate: Date
    var actualLoad: Double
    var plannedLoad: Double
    var distanceKm: Double
    var elevationGainM: Double
    var duration: TimeInterval

    init(
        weekStartDate: Date,
        actualLoad: Double = 0,
        plannedLoad: Double = 0,
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        duration: TimeInterval = 0
    ) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.actualLoad = actualLoad
        self.plannedLoad = plannedLoad
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.duration = duration
    }
}
