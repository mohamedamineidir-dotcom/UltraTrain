import Foundation

struct VolumeAdjustment: Equatable, Sendable {
    let sessionId: UUID
    let addedDistanceKm: Double
    let addedElevationGainM: Double
    let newType: SessionType?
}

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

enum PlanAdjustmentType: String, Sendable {
    case rescheduleKeySession
    case reduceVolumeAfterLowAdherence
    case convertToRecoveryWeek
    case bulkMarkMissedAsSkipped
    case reduceFatigueLoad
    case swapToRecovery
    case reduceLoadLowRecovery
    case swapToRecoveryLowRecovery
    case redistributeMissedVolume
    case convertEasyToQuality
    case reduceTargetDueToAccumulatedMissed
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
