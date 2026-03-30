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
    var strengthTrainingPreference: StrengthTrainingPreference = .no
    var strengthTrainingLocation: StrengthTrainingLocation = .home

    // MARK: - Terrain & Environment

    var runningTerrain: TerrainType = .trail
    var uphillDuration: UphillDuration? = nil
    var treadmillMaxIncline: TreadmillIncline? = nil

    // MARK: - Derived Fitness Metrics (from PBs)

    /// Estimated VO2max in ml/kg/min.
    var vo2max: Double?
    /// Maximal Aerobic Speed (VMA) in km/h.
    var vmaKmh: Double?
    /// Pace at ~60 min threshold (seuil 60) in seconds/km.
    var thresholdPace60MinPerKm: Double?
    /// Pace at ~30 min threshold (seuil 30) in seconds/km.
    var thresholdPace30MinPerKm: Double?

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
    }
}
