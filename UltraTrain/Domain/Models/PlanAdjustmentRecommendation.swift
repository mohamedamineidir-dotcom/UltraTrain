import Foundation

struct PlanAdjustmentRecommendation: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: PlanAdjustmentType
    let severity: AdjustmentSeverity
    let title: String
    let message: String
    let actionLabel: String
    let affectedSessionIds: [UUID]
}

enum PlanAdjustmentType: String, Sendable {
    case rescheduleKeySession
    case reduceVolumeAfterLowAdherence
    case convertToRecoveryWeek
    case bulkMarkMissedAsSkipped
}

enum AdjustmentSeverity: String, Comparable, Sendable {
    case suggestion
    case recommended
    case urgent

    private var sortOrder: Int {
        switch self {
        case .urgent: 2
        case .recommended: 1
        case .suggestion: 0
        }
    }

    static func < (lhs: AdjustmentSeverity, rhs: AdjustmentSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
