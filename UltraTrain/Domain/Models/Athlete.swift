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
    /// Drives the tenure multiplier in PersonalizationProfile
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

    /// Adaptive training-fitness anchor: a 5K-equivalent time (seconds)
    /// that ratchets faster as the athlete demonstrates sustained
    /// improvement across their training (faster quality/easy efforts at
    /// the right effort). Nil until enough evidence accumulates, then it
    /// floors the PR/VMA-derived fitness so training paces evolve a little
    /// over a prep without waiting for a freshly logged PR. Bounded by an
    /// experience-scaled ceiling so it stays realistic and gradual.
    var adaptiveFitness5KSeconds: TimeInterval?

    // MARK: - Comeback pace handicap

    /// Temporary slowdown applied to ALL derived training paces after a
    /// break (e.g. 1.06 = 6% slower), decaying linearly back to 1.0 between
    /// `comebackStart` and `comebackUntil`. Lets a returning, detrained
    /// athlete train at appropriate (easier) paces, then recover to normal
    /// over the rebuild. Nil = no handicap.
    var comebackPaceFactor: Double?
    var comebackStart: Date?
    var comebackUntil: Date?

    /// Current comeback pace multiplier (≥ 1.0), interpolated by date.
    /// Returns 1.0 (no effect) once the handicap has decayed or isn't set.
    func currentComebackPaceFactor(asOf date: Date = .now) -> Double {
        guard let factor = comebackPaceFactor, let start = comebackStart, let until = comebackUntil,
              factor > 1.0, until > start else { return 1.0 }
        if date <= start { return factor }
        if date >= until { return 1.0 }
        let progress = date.timeIntervalSince(start) / until.timeIntervalSince(start)
        return factor + (1.0 - factor) * progress
    }

    // MARK: - Menstrual cycle awareness (opt-in)

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
    }
}
