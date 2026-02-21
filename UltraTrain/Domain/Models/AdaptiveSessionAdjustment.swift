import Foundation

enum AdjustmentReason: String, Sendable, CaseIterable {
    case readinessTooLow
    case readinessHighUpgrade
    case poorSleep
    case highFatigue
    case weatherConditions
    case compoundFatigue
}

struct AdaptiveSessionAdjustment: Identifiable, Equatable, Sendable {
    let id: UUID
    var originalSessionId: UUID
    var originalType: SessionType
    var originalIntensity: Intensity
    var adjustedType: SessionType
    var adjustedIntensity: Intensity
    var adjustedDistanceKm: Double?
    var adjustedDuration: TimeInterval?
    var reason: AdjustmentReason
    var reasonText: String
    var confidencePercent: Int

    var isUpgrade: Bool {
        adjustedIntensity.rawValue > originalIntensity.rawValue ||
        (adjustedType == .tempo && originalType == .recovery)
    }

    var isDowngrade: Bool {
        adjustedIntensity.rawValue < originalIntensity.rawValue ||
        (adjustedType == .recovery && originalType != .recovery && originalType != .rest)
    }
}
