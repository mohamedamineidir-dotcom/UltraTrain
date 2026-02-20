import Foundation
import SwiftData

@Model
final class CompletedRunSwiftDataModel {
    var id: UUID = UUID()
    var athleteId: UUID = UUID()
    var date: Date = Date()
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var duration: Double = 0
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var averagePaceSecondsPerKm: Double = 0
    @Attribute(.externalStorage) var gpsTrackData: Data = Data()
    @Relationship(deleteRule: .cascade, inverse: \SplitSwiftDataModel.run)
    var splits: [SplitSwiftDataModel] = []
    var linkedSessionId: UUID?
    var linkedRaceId: UUID?
    var notes: String?
    var pausedDuration: Double = 0
    var gearIds: [UUID] = []
    @Attribute(.externalStorage) var nutritionIntakeData: Data = Data()
    var stravaActivityId: Int?
    var isStravaImport: Bool = false
    var isHealthKitImport: Bool = false
    var healthKitWorkoutUUID: String?
    var weatherData: Data = Data()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        athleteId: UUID = UUID(),
        date: Date = Date(),
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        elevationLossM: Double = 0,
        duration: Double = 0,
        averageHeartRate: Int? = nil,
        maxHeartRate: Int? = nil,
        averagePaceSecondsPerKm: Double = 0,
        gpsTrackData: Data = Data(),
        splits: [SplitSwiftDataModel] = [],
        linkedSessionId: UUID? = nil,
        linkedRaceId: UUID? = nil,
        notes: String? = nil,
        pausedDuration: Double = 0,
        gearIds: [UUID] = [],
        nutritionIntakeData: Data = Data(),
        stravaActivityId: Int? = nil,
        isStravaImport: Bool = false,
        isHealthKitImport: Bool = false,
        healthKitWorkoutUUID: String? = nil,
        weatherData: Data = Data(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.athleteId = athleteId
        self.date = date
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
        self.gpsTrackData = gpsTrackData
        self.splits = splits
        self.linkedSessionId = linkedSessionId
        self.linkedRaceId = linkedRaceId
        self.notes = notes
        self.pausedDuration = pausedDuration
        self.gearIds = gearIds
        self.nutritionIntakeData = nutritionIntakeData
        self.stravaActivityId = stravaActivityId
        self.isStravaImport = isStravaImport
        self.isHealthKitImport = isHealthKitImport
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.weatherData = weatherData
        self.updatedAt = updatedAt
    }
}
