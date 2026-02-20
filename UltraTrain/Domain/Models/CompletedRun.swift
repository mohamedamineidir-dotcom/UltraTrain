import Foundation

struct CompletedRun: Identifiable, Equatable, Sendable {
    let id: UUID
    var athleteId: UUID
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var duration: TimeInterval
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var averagePaceSecondsPerKm: Double
    var gpsTrack: [TrackPoint]
    var splits: [Split]
    var linkedSessionId: UUID?
    var linkedRaceId: UUID?
    var notes: String?
    var pausedDuration: TimeInterval
    var gearIds: [UUID] = []
    var nutritionIntakeLog: [NutritionIntakeEntry] = []
    var stravaActivityId: Int? = nil
    var isStravaImport: Bool = false
    var isHealthKitImport: Bool = false
    var healthKitWorkoutUUID: String? = nil

    var totalDuration: TimeInterval {
        duration + pausedDuration
    }

    var paceFormatted: String {
        let minutes = Int(averagePaceSecondsPerKm) / 60
        let seconds = Int(averagePaceSecondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

struct TrackPoint: Equatable, Sendable {
    var latitude: Double
    var longitude: Double
    var altitudeM: Double
    var timestamp: Date
    var heartRate: Int?
}

struct Split: Identifiable, Equatable, Sendable {
    let id: UUID
    var kilometerNumber: Int
    var duration: TimeInterval
    var elevationChangeM: Double
    var averageHeartRate: Int?
}
