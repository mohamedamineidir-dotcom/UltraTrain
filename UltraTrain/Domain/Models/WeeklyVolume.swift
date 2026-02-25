import Foundation

struct WeeklyVolume: Identifiable, Equatable {
    let id: Date
    var weekStartDate: Date
    var distanceKm: Double
    var elevationGainM: Double
    var duration: TimeInterval
    var runCount: Int
    var plannedDistanceKm: Double
    var plannedElevationGainM: Double

    init(
        weekStartDate: Date,
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        duration: TimeInterval = 0,
        runCount: Int = 0,
        plannedDistanceKm: Double = 0,
        plannedElevationGainM: Double = 0
    ) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.duration = duration
        self.runCount = runCount
        self.plannedDistanceKm = plannedDistanceKm
        self.plannedElevationGainM = plannedElevationGainM
    }
}
