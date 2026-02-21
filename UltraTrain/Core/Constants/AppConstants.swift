import Foundation

enum AppConstants {
    enum HeartRateZone {
        static let zone1Range = 0.50...0.60  // Recovery
        static let zone2Range = 0.60...0.70  // Aerobic base
        static let zone3Range = 0.70...0.80  // Tempo
        static let zone4Range = 0.80...0.90  // Threshold
        static let zone5Range = 0.90...1.00  // VO2max

        static func zone(
            for heartRate: Int,
            maxHeartRate: Int,
            customThresholds: [Int]? = nil
        ) -> Int {
            RunStatisticsCalculator.heartRateZone(
                heartRate: heartRate,
                maxHeartRate: maxHeartRate,
                customThresholds: customThresholds
            )
        }
    }

    enum Elevation {
        /// Kilian's coefficient: meters of D+ equivalent to 1 km horizontal
        static let effectiveDistanceRatio: Double = 100.0
    }

    enum Debounce {
        static let searchMilliseconds: Int = 300
    }
}
