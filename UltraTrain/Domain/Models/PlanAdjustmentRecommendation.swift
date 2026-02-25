import Foundation

struct PlanAdjustmentRecommendation: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: PlanAdjustmentType
    let severity: AdjustmentSeverity
    let title: String
    let message: String
    let actionLabel: String
    let affectedSessionIds: [UUID]
    var volumeAdjustments: [VolumeAdjustment] = []
}
