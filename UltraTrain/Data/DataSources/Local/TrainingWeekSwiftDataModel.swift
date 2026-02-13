import Foundation
import SwiftData

@Model
final class TrainingWeekSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var weekNumber: Int
    var startDate: Date
    var endDate: Date
    var phaseRaw: String
    @Relationship(deleteRule: .cascade) var sessions: [TrainingSessionSwiftDataModel]
    var isRecoveryWeek: Bool
    var targetVolumeKm: Double
    var targetElevationGainM: Double

    init(
        id: UUID,
        weekNumber: Int,
        startDate: Date,
        endDate: Date,
        phaseRaw: String,
        sessions: [TrainingSessionSwiftDataModel],
        isRecoveryWeek: Bool,
        targetVolumeKm: Double,
        targetElevationGainM: Double
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.phaseRaw = phaseRaw
        self.sessions = sessions
        self.isRecoveryWeek = isRecoveryWeek
        self.targetVolumeKm = targetVolumeKm
        self.targetElevationGainM = targetElevationGainM
    }
}
