import Foundation
import SwiftData

@Model
final class SplitSwiftDataModel {
    var id: UUID = UUID()
    var kilometerNumber: Int = 0
    var duration: Double = 0
    var elevationChangeM: Double = 0
    var averageHeartRate: Int?
    var run: CompletedRunSwiftDataModel?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        kilometerNumber: Int = 0,
        duration: Double = 0,
        elevationChangeM: Double = 0,
        averageHeartRate: Int? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.kilometerNumber = kilometerNumber
        self.duration = duration
        self.elevationChangeM = elevationChangeM
        self.averageHeartRate = averageHeartRate
        self.updatedAt = updatedAt
    }
}
