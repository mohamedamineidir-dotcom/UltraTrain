import Foundation

enum WatchConfiguration {

    enum GPS {
        static let distanceFilterM: Double = 10.0
        static let maxAccuracyM: Double = 50.0
    }

    enum AutoPause {
        static let pauseSpeedThreshold: Double = 0.5 // m/s
        static let resumeSpeedThreshold: Double = 0.8 // m/s
        static let pauseDelay: TimeInterval = 5.0
    }

    enum NutritionReminders {
        static let hydrationIntervalSeconds: TimeInterval = 1200  // 20 min
        static let fuelIntervalSeconds: TimeInterval = 2700       // 45 min
        static let maxScheduleDuration: TimeInterval = 43200      // 12 hours
    }

    enum Timer {
        static let interval: TimeInterval = 1.0
    }
}
