import Foundation
import os

enum AppConfiguration {
    static let appName = "UltraTrain"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    enum API {
        static let baseURL: URL = {
            #if DEBUG
            return URL(string: "https://api-dev.ultratrain.app/v1")!
            #else
            return URL(string: "https://api.ultratrain.app/v1")!
            #endif
        }()
        static let timeoutInterval: TimeInterval = 30
    }

    enum GPS {
        static let activeRunAccuracy: Double = 10.0 // kCLLocationAccuracyBest approx
        static let activeRunDistanceFilter: Double = 5.0
        static let backgroundAccuracy: Double = 100.0 // kCLLocationAccuracyNearestTenMeters approx
        static let backgroundDistanceFilter: Double = 20.0
    }

    enum Training {
        static let maxWeeklyVolumeIncreasePercent: Double = 10.0
        static let recoveryWeekVolumeReductionPercent: Double = 35.0
        static let recoveryWeekCycle: Int = 3 // recovery every Nth week
    }

    enum Nutrition {
        static let caloriesPerKgPerHourLow: Double = 4.0
        static let caloriesPerKgPerHourHigh: Double = 6.0
        static let hydrationMlPerHourLow: Int = 400
        static let hydrationMlPerHourHigh: Int = 800
        static let sodiumMgPerHour: Int = 600
    }
}
