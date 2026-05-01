import Foundation

struct Athlete: Identifiable, Equatable, Sendable {
    let id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var weightKg: Double
    var heightCm: Double
    var restingHeartRate: Int
    var maxHeartRate: Int
    var experienceLevel: ExperienceLevel
    var weeklyVolumeKm: Double
    var longestRunKm: Double
    var preferredUnit: UnitPreference
    var customZoneThresholds: [Int]?
    var personalBests: [PersonalBest] = []
    var trailPersonalBests: [TrailPersonalBest] = []
    var trainingPhilosophy: TrainingPhilosophy = .balanced
    var preferredRunsPerWeek: Int = 5
    var displayName: String? = nil
    var bio: String? = nil
    var profilePhotoData: Data? = nil
    var isPublicProfile: Bool = false
    var weightGoal: WeightGoal = .maintain
    var biologicalSex: BiologicalSex = .male
    var verticalGainEnvironment: VerticalGainEnvironment = .mountain

    // MARK: - Injury & Strength Training

    var painFrequency: PainFrequency = .never
    var injuryCountLastYear: InjuryCount = .none
    var hasRecentInjury: Bool = false
    /// Recurring injury structures the athlete flagged at onboarding.
    /// Drives PersonalizationProfile injury-volume penalty and (in v2)
    /// session-selection bias.
    var injuryStructures: Set<InjuryStructure> = []
    var strengthTrainingPreference: StrengthTrainingPreference = .no
    var strengthTrainingLocation: StrengthTrainingLocation = .home

    // MARK: - Tenure

    /// Years of consistent running (≥1×/week). 0 means unknown.
    /// Drives the tenure multiplier in PersonalizationProfile —
    /// a 10-year intermediate tolerates more peak load than a
    /// 2-year intermediate at the same tier label.
    var runningYears: Double = 0

    // MARK: - Terrain & Environment

    var runningTerrain: TerrainType = .trail
    var uphillDuration: UphillDuration? = nil
    var treadmillMaxIncline: TreadmillIncline? = nil
    var intervalFocus: IntervalFocus = .mixed

    // MARK: - Derived Fitness Metrics (from PBs)

    /// Estimated VO2max in ml/kg/min.
    var vo2max: Double?
    /// Maximal Aerobic Speed (VMA) in km/h.
    var vmaKmh: Double?
    /// Pace at ~60 min threshold (seuil 60) in seconds/km.
    var thresholdPace60MinPerKm: Double?
    /// Pace at ~30 min threshold (seuil 30) in seconds/km.
    var thresholdPace30MinPerKm: Double?

    // MARK: - Menstrual cycle awareness (opt-in)

    /// When true, the plan + coach advice surface cycle-aware cues
    /// (luteal-phase carb reminders, mild intensity scaler). Off by
    /// default — only meaningful for menstruating athletes who choose
    /// to log cycle dates. Sims (2016), Mountjoy (2014 / RED-S IOC).
    var cycleAware: Bool = false
    /// Typical cycle length in days. Default 28; range 21-35 covers
    /// most ranges. Used to compute current phase.
    var cycleLengthDays: Int = 28
    /// First day of most recent menstruation. Used as the cycle anchor.
    /// Nil disables phase computation even when cycleAware is true.
    var lastPeriodStartDate: Date? = nil

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
    }
}
