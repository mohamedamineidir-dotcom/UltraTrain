import Foundation
import SwiftData

@Model
final class TrainingPlanSwiftDataModel {
    var id: UUID = UUID()
    var athleteId: UUID = UUID()
    var targetRaceId: UUID = UUID()
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \TrainingWeekSwiftDataModel.plan)
    var weeks: [TrainingWeekSwiftDataModel] = []
    var intermediateRaceIds: [UUID] = []
    var intermediateRaceSnapshotsData: Data?
    var workoutsData: Data?
    var updatedAt: Date = Date()
    /// Baseline VMA captured when a regression-pending re-test was
    /// scheduled. Optional with default nil for SwiftData migration.
    var pendingRetestOriginalBaselineVma: Double? = nil

    init(
        id: UUID = UUID(),
        athleteId: UUID = UUID(),
        targetRaceId: UUID = UUID(),
        createdAt: Date = Date(),
        weeks: [TrainingWeekSwiftDataModel] = [],
        intermediateRaceIds: [UUID] = [],
        intermediateRaceSnapshotsData: Data? = nil,
        workoutsData: Data? = nil,
        updatedAt: Date = Date(),
        pendingRetestOriginalBaselineVma: Double? = nil
    ) {
        self.id = id
        self.athleteId = athleteId
        self.targetRaceId = targetRaceId
        self.createdAt = createdAt
        self.weeks = weeks
        self.intermediateRaceIds = intermediateRaceIds
        self.intermediateRaceSnapshotsData = intermediateRaceSnapshotsData
        self.workoutsData = workoutsData
        self.updatedAt = updatedAt
        self.pendingRetestOriginalBaselineVma = pendingRetestOriginalBaselineVma
    }
}
