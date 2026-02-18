import Foundation
import SwiftData

@Model
final class TrainingWeekSwiftDataModel {
    var id: UUID = UUID()
    var weekNumber: Int = 0
    var startDate: Date = Date()
    var endDate: Date = Date()
    var phaseRaw: String = "base"
    @Relationship(deleteRule: .cascade, inverse: \TrainingSessionSwiftDataModel.week)
    var sessions: [TrainingSessionSwiftDataModel] = []
    var isRecoveryWeek: Bool = false
    var targetVolumeKm: Double = 0
    var targetElevationGainM: Double = 0
    var plan: TrainingPlanSwiftDataModel?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        weekNumber: Int = 0,
        startDate: Date = Date(),
        endDate: Date = Date(),
        phaseRaw: String = "base",
        sessions: [TrainingSessionSwiftDataModel] = [],
        isRecoveryWeek: Bool = false,
        targetVolumeKm: Double = 0,
        targetElevationGainM: Double = 0,
        updatedAt: Date = Date()
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
        self.updatedAt = updatedAt
    }
}
