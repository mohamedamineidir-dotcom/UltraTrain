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
        static let lowAdherenceThreshold: Double = 0.5
        static let lowAdherenceVolumeReductionPercent: Double = 20.0
        static let extendedGapDays: Int = 7
        static let staleMissedSessionThreshold: Int = 3
    }

    enum RunTracking {
        static let autoPauseSpeedThreshold: Double = 0.5 // m/s
        static let autoResumeSpeedThreshold: Double = 0.8 // m/s (hysteresis)
        static let autoPauseDelay: TimeInterval = 5.0 // seconds below threshold
        static let timerInterval: TimeInterval = 1.0
    }

    enum Nutrition {
        static let caloriesPerKgPerHourLow: Double = 4.0
        static let caloriesPerKgPerHourHigh: Double = 6.0
        static let hydrationMlPerHourLow: Int = 400
        static let hydrationMlPerHourHigh: Int = 800
        static let sodiumMgPerHour: Int = 600
    }

    enum WatchConnectivity {
        static let updateInterval: TimeInterval = 1.0
    }

    enum LiveActivity {
        static let updateIntervalSeconds: TimeInterval = 4.0
    }

    enum NutritionReminders {
        static let hydrationIntervalSeconds: TimeInterval = 1200  // 20 min
        static let fuelIntervalSeconds: TimeInterval = 2700       // 45 min
        static let autoDismissSeconds: TimeInterval = 15
        static let maxScheduleDuration: TimeInterval = 43200      // 12 hours
    }

    enum LiveRace {
        static let crossingBannerDismissSeconds: TimeInterval = 8
    }

    enum Weather {
        static let currentCacheTTL: TimeInterval = 900
        static let hourlyCacheTTL: TimeInterval = 1800
        static let dailyCacheTTL: TimeInterval = 3600
        static let maxForecastDays: Int = 10
        static let sessionForecastHoursAhead: Int = 48
    }

    enum PacingAlerts {
        static let minDistanceKm: Double = 0.5
        static let cooldownSeconds: TimeInterval = 60
        static let minorDeviationPercent: Double = 10.0
        static let majorDeviationPercent: Double = 20.0
        static let onPaceBandPercent: Double = 5.0
        static let autoDismissSeconds: TimeInterval = 8
    }

    enum PacingStrategy {
        static let defaultAidStationDwellSeconds: TimeInterval = 300
        static let easyGradientThresholdMPerKm: Double = 20.0
        static let hardGradientThresholdMPerKm: Double = 60.0
        static let descentGradientThresholdMPerKm: Double = 30.0
    }

    enum Recovery {
        static let targetSleepHoursLow: Double = 7.0
        static let targetSleepHoursHigh: Double = 9.0
        static let lowRecoveryThreshold: Int = 40
        static let criticalRecoveryThreshold: Int = 20
        static let sleepQualityWeight: Double = 0.35
        static let sleepConsistencyWeight: Double = 0.15
        static let restingHRWeight: Double = 0.25
        static let trainingLoadWeight: Double = 0.25
    }

    enum Strava {
        static let clientId: String = Bundle.main.infoDictionary?["STRAVA_CLIENT_ID"] as? String ?? ""
        static let clientSecret: String = Bundle.main.infoDictionary?["STRAVA_CLIENT_SECRET"] as? String ?? ""
        static let callbackURLScheme = "ultratrain"
        static let authorizeURL = "https://www.strava.com/oauth/mobile/authorize"
        static let tokenURL = "https://www.strava.com/oauth/token"
        static let apiBaseURL = "https://www.strava.com/api/v3"
        static let requiredScopes = "read,activity:read_all,activity:write"
    }
}
