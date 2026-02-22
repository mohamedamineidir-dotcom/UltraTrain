import Foundation
import SwiftData

@Model
final class IntervalWorkoutSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var descriptionText: String = ""
    @Attribute(.externalStorage) var phasesData: Data = Data()
    var categoryRaw: String = "speedWork"
    var estimatedDurationSeconds: Double = 0
    var estimatedDistanceKm: Double = 0
    var isUserCreated: Bool = true
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        descriptionText: String = "",
        phasesData: Data = Data(),
        categoryRaw: String = "speedWork",
        estimatedDurationSeconds: Double = 0,
        estimatedDistanceKm: Double = 0,
        isUserCreated: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.phasesData = phasesData
        self.categoryRaw = categoryRaw
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.estimatedDistanceKm = estimatedDistanceKm
        self.isUserCreated = isUserCreated
        self.updatedAt = updatedAt
    }
}
