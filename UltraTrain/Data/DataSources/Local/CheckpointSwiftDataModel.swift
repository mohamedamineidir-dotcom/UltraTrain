import Foundation
import SwiftData

@Model
final class CheckpointSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var distanceFromStartKm: Double = 0
    var elevationM: Double = 0
    var hasAidStation: Bool = false
    var race: RaceSwiftDataModel?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        distanceFromStartKm: Double = 0,
        elevationM: Double = 0,
        hasAidStation: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.distanceFromStartKm = distanceFromStartKm
        self.elevationM = elevationM
        self.hasAidStation = hasAidStation
        self.updatedAt = updatedAt
    }
}
