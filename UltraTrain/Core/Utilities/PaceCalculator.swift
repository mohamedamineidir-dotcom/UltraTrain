import Foundation

enum PaceCalculator {

    /// Returns a pace range (seconds/km) for a given intensity, based on athlete's threshold pace.
    /// thresholdPace is in seconds/km (e.g., 300 = 5:00/km).
    static func paceRange(
        for intensity: Intensity,
        thresholdPacePerKm: TimeInterval
    ) -> (min: TimeInterval, max: TimeInterval) {
        switch intensity {
        case .easy:
            return (thresholdPacePerKm * 1.25, thresholdPacePerKm * 1.35)
        case .moderate:
            return (thresholdPacePerKm * 1.00, thresholdPacePerKm * 1.10)
        case .hard:
            return (thresholdPacePerKm * 0.90, thresholdPacePerKm * 0.95)
        case .maxEffort:
            return (thresholdPacePerKm * 0.85, thresholdPacePerKm * 0.90)
        }
    }

    /// Karvonen HR zone range from resting + max HR.
    static func heartRateRange(
        for intensity: Intensity,
        restingHR: Int,
        maxHR: Int
    ) -> (min: Int, max: Int) {
        let reserve = Double(maxHR - restingHR)
        let (lowPct, highPct): (Double, Double) = switch intensity {
        case .easy: (0.50, 0.65)
        case .moderate: (0.65, 0.80)
        case .hard: (0.80, 0.90)
        case .maxEffort: (0.90, 1.0)
        }
        let low = Int(Double(restingHR) + reserve * lowPct)
        let high = Int(Double(restingHR) + reserve * highPct)
        return (low, high)
    }

    /// Format seconds/km to "X:XX" string.
    static func formatPace(_ secondsPerKm: TimeInterval) -> String {
        let total = Int(secondsPerKm)
        let mins = total / 60
        let secs = total % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
