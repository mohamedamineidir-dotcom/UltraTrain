import Foundation
import SwiftData

@Model
final class CheckpointSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var distanceFromStartKm: Double
    var elevationM: Double
    var hasAidStation: Bool

    init(
        id: UUID,
        name: String,
        distanceFromStartKm: Double,
        elevationM: Double,
        hasAidStation: Bool
    ) {
        self.id = id
        self.name = name
        self.distanceFromStartKm = distanceFromStartKm
        self.elevationM = elevationM
        self.hasAidStation = hasAidStation
    }
}
