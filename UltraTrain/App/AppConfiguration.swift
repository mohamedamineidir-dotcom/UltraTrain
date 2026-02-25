import Foundation
import os

enum AppConfiguration {
    static let appName = "UltraTrain"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    enum API {
        static let baseURL: URL = {
            #if DEBUG
            return URL(string: "https://ultratrain-production.up.railway.app/v1")!
            #else
            return URL(string: "https://ultratrain-production.up.railway.app/v1")!
            #endif
        }()
        static let timeoutInterval: TimeInterval = 30
        static let hmacSecret: String = Bundle.main.infoDictionary?["HMAC_SIGNING_SECRET"] as? String ?? ""
        static let pinnedHost: String = "ultratrain-production.up.railway.app"
        // TODO: Extract server certificate hash before production release.
        // See CertificatePinningDelegate.swift for extraction instructions.
        static let certificatePinHashes: [String] = []
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
        static let maxSessionVolumeIncreasePercent: Double = 20.0
        static let accumulatedMissedVolumeThresholdKm: Double = 30.0
        static let accumulatedMissedVolumeReductionPercent: Double = 15.0
        static let redistributionLookbackWeeks: Int = 2
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
        static let recalculationDeltaThresholdPercent: Double = 3.0
        static let guidanceUpdateMinDistanceKm: Double = 0.3
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

    enum WeatherImpact {
        static let heatBaselineCelsius: Double = 15.0
        static let heatImpactPerDegree: Double = 0.004
        static let maxHeatImpact: Double = 0.20
        static let humidityCompoundingThreshold: Double = 0.70
        static let humidityCompoundingMax: Double = 1.3
        static let heavyRainImpact: Double = 0.04
        static let moderateRainImpact: Double = 0.02
        static let lightRainImpact: Double = 0.01
        static let windThresholdKmh: Double = 25.0
        static let strongWindThresholdKmh: Double = 40.0
        static let windImpact: Double = 0.03
        static let strongWindImpact: Double = 0.05
        static let coldThresholdCelsius: Double = 5.0
        static let coldImpactPerDegree: Double = 0.005
        static let maxColdImpact: Double = 0.03
        static let heatHydrationMultiplier: Double = 1.5
        static let heatSodiumMultiplier: Double = 1.3
        static let coldCalorieMultiplier: Double = 1.1
    }

    enum HRZoneAlerts {
        static let mildDriftSeconds: TimeInterval = 60
        static let moderateDriftSeconds: TimeInterval = 180
        static let significantDriftSeconds: TimeInterval = 300
        static let alertCooldownSeconds: TimeInterval = 30
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

    enum IntervalGuidance {
        static let countdownSeconds: Int = 3
        static let phaseTransitionBannerDismissSeconds: TimeInterval = 5
        static let minPhaseDurationSeconds: TimeInterval = 10
        static let maxPhaseCount: Int = 50
    }

    enum Safety {
        static let fallImpactThresholdG: Double = 3.0
        static let countdownSeconds: Int = 30
        static let noMovementDefaultMinutes: Int = 5
        static let motionBufferSize: Int = 100
        static let sosLongPressSeconds: Double = 1.5
    }

    enum VoiceCoaching {
        static let defaultSpeechRate: Float = 0.5
        static let maxQueueSize = 3
        static let distanceSplitKm: Double = 1.0
        static let defaultTimeSplitMinutes = 5
    }

    enum AICoach {
        static let paceDeclineThreshold: Double = 0.05      // 5% pace decline
        static let hrDriftThreshold: Double = 0.08           // 8% HR drift
        static let sleepDeclineThreshold: Double = 0.15      // 15% sleep quality decline
        static let rpeRiseThreshold: Double = 1.5            // RPE points rise
        static let trendMinDataPoints: Int = 5               // minimum runs for trend analysis
        static let fatigueDetectionWindowDays: Int = 14      // lookback window
        static let performanceTrendWindowDays: Int = 28      // lookback for trends
        static let compoundFatigueThreshold: Int = 2         // signals needed for compound
        static let longRunThresholdKm: Double = 15.0         // for endurance fade analysis
        static let deloadSuggestionDays: Int = 3             // default deload suggestion
    }

    enum MLPredictor {
        static let minRunsForLowConfidence: Int = 10
        static let minRunsForMediumConfidence: Int = 20
        static let minRunsForHighConfidence: Int = 50
        static let algorithmicWeightLow: Double = 0.70       // <20 runs
        static let algorithmicWeightMedium: Double = 0.50    // 20-50 runs
        static let algorithmicWeightHigh: Double = 0.30      // 50+ runs
        static let modelVersion = "1.0"
    }
}
