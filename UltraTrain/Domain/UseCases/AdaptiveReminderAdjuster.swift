import Foundation

enum AdaptiveReminderAdjuster {

    struct RunConditions: Sendable {
        let currentHeartRate: Int?
        let maxHeartRate: Int?
        let elapsedDistanceKm: Double
        let currentPaceSecondsPerKm: Double?
        let averagePaceSecondsPerKm: Double?
    }

    static func intervalMultiplier(
        for type: NutritionReminderType,
        conditions: RunConditions
    ) -> Double {
        var multiplier = 1.0

        // High HR → more frequent reminders
        if let current = conditions.currentHeartRate,
           let max = conditions.maxHeartRate,
           max > 0 {
            let hrPercent = Double(current) / Double(max)
            if hrPercent > 0.80 {
                switch type {
                case .hydration: multiplier *= 0.75
                case .fuel: multiplier *= 0.90
                case .electrolyte: multiplier *= 0.75
                }
            }
        }

        // Slower pace → less frequent (lower effort)
        if let current = conditions.currentPaceSecondsPerKm,
           let average = conditions.averagePaceSecondsPerKm,
           average > 0 {
            let paceRatio = current / average
            if paceRatio > 1.15 {
                multiplier *= 1.15
            }
        }

        // Long distance → more frequent (late-race needs)
        if conditions.elapsedDistanceKm > 30 {
            multiplier *= 0.90
        }

        return min(max(multiplier, 0.5), 1.5)
    }
}
