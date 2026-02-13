import Foundation
import SwiftData

@Model
final class SplitSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var kilometerNumber: Int
    var duration: Double
    var elevationChangeM: Double
    var averageHeartRate: Int?

    init(
        id: UUID,
        kilometerNumber: Int,
        duration: Double,
        elevationChangeM: Double,
        averageHeartRate: Int?
    ) {
        self.id = id
        self.kilometerNumber = kilometerNumber
        self.duration = duration
        self.elevationChangeM = elevationChangeM
        self.averageHeartRate = averageHeartRate
    }
}
