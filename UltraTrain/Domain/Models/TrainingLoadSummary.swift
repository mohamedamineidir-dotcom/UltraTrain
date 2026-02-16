import Foundation

struct WeeklyLoadData: Identifiable, Equatable, Sendable {
    let id: Date
    var weekStartDate: Date
    var actualLoad: Double      // effort-weighted: distanceKm + (elevationGainM / 100)
    var plannedLoad: Double     // from plan: targetVolumeKm + (targetElevationGainM / 100)
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

struct ACRDataPoint: Identifiable, Equatable, Sendable {
    let id: Date
    var date: Date
    var value: Double

    init(date: Date, value: Double) {
        self.id = date
        self.date = date
        self.value = value
    }
}

enum MonotonyLevel: String, Sendable {
    case low      // < 1.5 — good variety
    case normal   // 1.5 – 2.0
    case high     // > 2.0 — injury risk

    init(monotony: Double) {
        if monotony > 2.0 {
            self = .high
        } else if monotony >= 1.5 {
            self = .normal
        } else {
            self = .low
        }
    }

    var displayName: String {
        switch self {
        case .low: "Good Variety"
        case .normal: "Normal"
        case .high: "Too Monotonous"
        }
    }
}

struct TrainingLoadSummary: Equatable, Sendable {
    var currentWeekLoad: WeeklyLoadData
    var weeklyHistory: [WeeklyLoadData]    // 12 weeks
    var acrTrend: [ACRDataPoint]           // 28 days
    var monotony: Double
    var monotonyLevel: MonotonyLevel
}
