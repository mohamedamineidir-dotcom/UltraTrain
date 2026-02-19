import Foundation
import SwiftData

@Model
final class FinishEstimateSwiftDataModel {
    var id: UUID = UUID()
    var raceId: UUID = UUID()
    var athleteId: UUID = UUID()
    var calculatedAt: Date = Date()
    var optimisticTime: Double = 0
    var expectedTime: Double = 0
    var conservativeTime: Double = 0
    @Attribute(.externalStorage) var checkpointSplitsData: Data = Data()
    var confidencePercent: Double = 0
    var raceResultsUsed: Int = 0

    init(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        athleteId: UUID = UUID(),
        calculatedAt: Date = Date(),
        optimisticTime: Double = 0,
        expectedTime: Double = 0,
        conservativeTime: Double = 0,
        checkpointSplitsData: Data = Data(),
        confidencePercent: Double = 0,
        raceResultsUsed: Int = 0
    ) {
        self.id = id
        self.raceId = raceId
        self.athleteId = athleteId
        self.calculatedAt = calculatedAt
        self.optimisticTime = optimisticTime
        self.expectedTime = expectedTime
        self.conservativeTime = conservativeTime
        self.checkpointSplitsData = checkpointSplitsData
        self.confidencePercent = confidencePercent
        self.raceResultsUsed = raceResultsUsed
    }
}
