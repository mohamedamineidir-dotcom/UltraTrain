import Foundation
import SwiftData

@Model
final class WorkoutRecipeSwiftDataModel {
    var id: String = UUID().uuidString
    var name: String = ""
    var sessionTypeRaw: String = "longRun"
    var targetDistanceKm: Double = 10
    var targetElevationGainM: Double = 0
    var estimatedDuration: Double = 3600
    var intensityRaw: String = "moderate"
    var categoryRaw: String = "trailSpecific"
    var descriptionText: String = ""
    var updatedAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        name: String = "",
        sessionTypeRaw: String = "longRun",
        targetDistanceKm: Double = 10,
        targetElevationGainM: Double = 0,
        estimatedDuration: Double = 3600,
        intensityRaw: String = "moderate",
        categoryRaw: String = "trailSpecific",
        descriptionText: String = "",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sessionTypeRaw = sessionTypeRaw
        self.targetDistanceKm = targetDistanceKm
        self.targetElevationGainM = targetElevationGainM
        self.estimatedDuration = estimatedDuration
        self.intensityRaw = intensityRaw
        self.categoryRaw = categoryRaw
        self.descriptionText = descriptionText
        self.updatedAt = updatedAt
    }
}
