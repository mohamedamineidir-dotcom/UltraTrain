import Foundation
import SwiftData

@Model
final class TrainingGoalSwiftDataModel {
    var id: UUID = UUID()
    var periodRaw: String = ""
    var targetDistanceKm: Double = 0
    var targetElevationM: Double = 0
    var targetRunCount: Int = 0
    var targetDurationSeconds: Double = 0
    var startDate: Date = Date()
    var endDate: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        periodRaw: String = "",
        targetDistanceKm: Double = 0,
        targetElevationM: Double = 0,
        targetRunCount: Int = 0,
        targetDurationSeconds: Double = 0,
        startDate: Date = Date(),
        endDate: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.periodRaw = periodRaw
        self.targetDistanceKm = targetDistanceKm
        self.targetElevationM = targetElevationM
        self.targetRunCount = targetRunCount
        self.targetDurationSeconds = targetDurationSeconds
        self.startDate = startDate
        self.endDate = endDate
        self.updatedAt = updatedAt
    }
}
