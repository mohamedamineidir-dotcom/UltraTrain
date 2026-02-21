import Foundation

struct OptimalSession: Identifiable, Equatable, Sendable {
    let id: UUID
    var recommendedType: SessionType
    var distanceKm: Double
    var elevationGainM: Double
    var duration: TimeInterval
    var intensity: Intensity
    var targetHeartRateZone: Int?
    var reasoning: String
    var replacesSessionId: UUID?
    var confidencePercent: Int
    var phase: TrainingPhase

    var isUpgrade: Bool {
        // true if recommending harder than originally planned
        replacesSessionId != nil && (intensity == .hard || intensity == .maxEffort)
    }

    var isDowngrade: Bool {
        // true if recommending easier than originally planned
        replacesSessionId != nil && (intensity == .easy || recommendedType == .recovery || recommendedType == .rest)
    }
}
