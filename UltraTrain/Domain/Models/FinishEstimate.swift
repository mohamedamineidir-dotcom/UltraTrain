import Foundation

/// Where the prediction's pace anchor came from. Drives the data-
/// source badge in the UI and the range-spread logic in the estimator.
enum FinishPredictionSource: String, Sendable, Codable {
    /// Recent completed runs supplied a measured pace anchor.
    case runs
    /// PBs converted via Riegel + Kilian. No completed runs yet —
    /// this is the day-0 estimate.
    case personalBests
    /// No PBs and no runs. Estimate derived from the experience-level
    /// fallback (`Race.estimatedDuration(experience:)`). Wide range.
    case experienceFallback

    /// Short user-facing label.
    var shortLabel: String {
        switch self {
        case .runs:               return "Refined from your training"
        case .personalBests:      return "Early estimate from your PBs"
        case .experienceFallback: return "General estimate"
        }
    }

    /// Helper copy explaining why the range looks the way it does.
    var explainer: String {
        switch self {
        case .runs:
            return "Updated from your recent training data. Range tightens as you log more sessions."
        case .personalBests:
            return "Built from your race PBs. Will refine as you log training — log a few runs to tighten the range."
        case .experienceFallback:
            return "We don't have PBs or training data yet. Add a recent race time on your profile, or log a few runs to refine the prediction."
        }
    }
}

struct FinishEstimate: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var raceId: UUID
    var athleteId: UUID
    var calculatedAt: Date
    var optimisticTime: TimeInterval
    var expectedTime: TimeInterval
    var conservativeTime: TimeInterval
    var checkpointSplits: [CheckpointSplit]
    var confidencePercent: Double
    var raceResultsUsed: Int
    var calibrationFactor: Double = 1.0
    var weatherMultiplier: Double? = nil
    var weatherImpactSummary: String? = nil
    /// Set by FinishTimeEstimator when computed. Optional + default
    /// nil so persisted estimates from before this change still
    /// decode. UI falls back to a generic label when nil.
    var predictionSource: FinishPredictionSource? = nil

    var expectedTimeFormatted: String {
        Self.formatDuration(expectedTime)
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh%02d", hours, minutes)
    }
}
