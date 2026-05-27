import Foundation

/// Where the prediction's pace anchor came from. Drives the data-
/// source badge in the UI and the range-spread logic in the estimator.
enum FinishPredictionSource: String, Sendable, Codable {
    /// Recent completed runs supplied a measured pace anchor.
    case runs
    /// PBs converted via Riegel + Kilian. No completed runs yet
    /// this is the day-0 estimate.
    case personalBests
    /// No PBs and no runs. Estimate derived from the experience-level
    /// fallback (`Race.estimatedDuration(experience:)`). Wide range.
    case experienceFallback

    /// Short user-facing label.
    var shortLabel: String {
        switch self {
        case .runs:               return "Refined from your training"
        case .personalBests:      return "Early estimate from your profile data"
        case .experienceFallback: return "General estimate"
        }
    }

    /// Helper copy explaining why the range looks the way it does.
    /// Generic across PB- and VMA-derived sources so it covers both
    /// "athlete has race PBs" and "athlete completed a fitness test."
    var explainer: String {
        switch self {
        case .runs:
            return "Updated from your recent training data. Range tightens as you log more sessions."
        case .personalBests:
            return "Built from your race PBs and any test results. Will refine as you log training, log a few runs to tighten the range."
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

    /// Formats a race time. Road races up to and including the marathon
    /// get second precision (M:SS or H:MM:SS) because a 10K at 36:12 vs
    /// 36:45 shifts target paces materially. Ultras and unknown contexts
    /// keep the existing minute-precision "XhYY" format.
    static func formatDuration(_ interval: TimeInterval, raceDistanceKm: Double? = nil) -> String {
        let totalSec = Int(interval.rounded())
        let hours = totalSec / 3600
        let minutes = (totalSec % 3600) / 60
        let seconds = totalSec % 60

        if let km = raceDistanceKm, km > 0, km <= 42.195 {
            if hours == 0 {
                return String(format: "%d:%02d", minutes, seconds)
            }
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%dh%02d", hours, minutes)
    }
}
