import Foundation
import os

@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository

    // MARK: - Navigation State

    var currentStep = 0
    let totalSteps = 13
    var isCompleted = false
    var isSaving = false
    var error: String?
    private(set) var savedAthleteId: UUID?
    var initialFirstName: String?
    var initialLastName: String?
    /// True when both names came from Sign in with Apple's
    /// AuthenticationServices credential, not from the user typing them
    /// in. Apple's Sign in with Apple design guidelines (Guideline 4)
    /// require not asking the user to provide info the framework already
    /// gave us — `AboutYouStepView` uses this to skip the name fields
    /// entirely instead of just pre-filling them.
    var nameProvidedByAppleSignIn: Bool {
        !(initialFirstName?.isEmpty ?? true) && !(initialLastName?.isEmpty ?? true)
    }

    // MARK: - Step 1: Experience

    var experienceLevel: ExperienceLevel?
    var preferredUnit: UnitPreference = .metric

    // MARK: - Step 2: Running History

    var weeklyVolumeKm: Double = 30
    var longestRunKm: Double = 15
    var isNewRunner = false

    // MARK: - Step 3: Personal Bests (Optional)

    var pb5kHours: Int = 0
    var pb5kMinutes: Int = 0
    var pb5kSeconds: Int = 0
    var pb5kDate: Date = .now

    var pb10kHours: Int = 0
    var pb10kMinutes: Int = 0
    var pb10kSeconds: Int = 0
    var pb10kDate: Date = .now

    var pbHalfHours: Int = 0
    var pbHalfMinutes: Int = 0
    var pbHalfSeconds: Int = 0
    var pbHalfDate: Date = .now

    var pbMarathonHours: Int = 0
    var pbMarathonMinutes: Int = 0
    var pbMarathonSeconds: Int = 0
    var pbMarathonDate: Date = .now

    // MARK: - Step 3: Trail Personal Bests (Optional)

    struct TrailPBEntry: Identifiable {
        let id = UUID()
        var distanceKm: Double = 50
        var elevationGainM: Double = 2000
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        var date: Date = .now

        var totalSeconds: TimeInterval {
            TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }

        var isValid: Bool {
            distanceKm > 0 && elevationGainM >= 0 && totalSeconds > 0
        }
    }

    var trailPBEntries: [TrailPBEntry] = []

    func addTrailPBEntry() {
        guard trailPBEntries.count < 5 else { return }
        trailPBEntries.append(TrailPBEntry())
    }

    func removeTrailPBEntry(at index: Int) {
        guard trailPBEntries.indices.contains(index) else { return }
        trailPBEntries.remove(at: index)
    }

    func buildTrailPBs() -> [TrailPersonalBest] {
        trailPBEntries.compactMap { entry in
            guard entry.isValid else { return nil }
            return TrailPersonalBest(
                id: UUID(),
                distanceKm: entry.distanceKm,
                elevationGainM: entry.elevationGainM,
                timeSeconds: entry.totalSeconds,
                date: entry.date
            )
        }
    }

    // MARK: - Step 4: Physical Data

    var firstName = ""
    var lastName = ""
    // invariant: Calendar.date(byAdding:) always succeeds for simple year/month offsets
    var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: .now)!
    var weightKg: Double = 70
    var heightCm: Double = 175
    var restingHeartRate: Int = 60
    var maxHeartRate: Int = 185
    var weightGoal: WeightGoal = .maintain
    var biologicalSex: BiologicalSex = .male

    // MARK: - Step 5: Race Goal

    var trainingPhilosophy: TrainingPhilosophy = .balanced
    /// Chosen by athletes not preparing for a race; drives the general-fitness plan.
    var trainingFocus: TrainingFocus = .maintainFitness
    var preferredRunsPerWeek: Int = 4
    var raceName = ""
    var raceDate = Calendar.current.date(byAdding: .month, value: 6, to: .now)!
    var raceDistanceKm: Double = 50
    var raceElevationGainM: Double = 2000
    var raceElevationLossM: Double = 2000
    var raceGoalType: RaceGoalSelection = .finish
    var raceTargetTimeHours: Int = 10
    var raceTargetTimeMinutes: Int = 0
    /// Seconds component of the target time. Only surfaced in the UI
    /// for road races up to marathon (inclusive) where the difference
    /// between e.g. 36:01 and 36:55 in a 10K is large enough that
    /// target paces would diverge. For longer trail/ultra goals the
    /// seconds picker stays hidden, minute precision is plenty.
    var raceTargetTimeSeconds: Int = 0
    var raceTargetRanking: Int = 50
    var raceTerrainDifficulty: TerrainDifficulty = .moderate
    var raceType: RaceType = .trail
    var isKnownRace: Bool = false
    /// T8: highest elevation on the course (m). Pre-populated from the
    /// known-race database when the athlete picks one; otherwise nil
    /// and no altitude advisory fires.
    var raceMaxElevationM: Double? = nil
    /// T8: whether trekking poles are allowed. Pre-populated from the
    /// known-race database; nil = unknown / no cue.
    var racePolesAllowed: Bool? = nil
    var targetRankingEstimatedTimeHours: Int = 10
    var targetRankingEstimatedTimeMinutes: Int = 0
    var verticalGainEnvironment: VerticalGainEnvironment = .mountain
    var hasNoRace = false

    // MARK: - Step 6: Injury & Strength Training

    var painFrequency: PainFrequency?
    var injuryCountLastYear: InjuryCount?
    var hasRecentInjury: Bool = false
    var strengthTrainingPreference: StrengthTrainingPreference?
    var strengthTrainingLocation: StrengthTrainingLocation?

    // MARK: - GoalTraining additions

    /// Backing storage for the terrain picker. Treated as the source of
    /// truth only once the athlete has explicitly tapped the picker
    /// until then `effectiveRunningTerrain` derives the default from the
    /// A-race profile so a road A-race lands on Road instead of Trail.
    var runningTerrain: TerrainType = .trail
    /// Flips to `true` the first time the athlete touches the terrain
    /// picker in `GoalTrainingStepView`. Once set we stop deriving and
    /// honour their choice, even if they later go back and change the
    /// race profile.
    var runningTerrainUserPicked: Bool = false

    /// Terrain default inferred from the A-race profile when the athlete
    /// hasn't explicitly picked yet. Road A-races up to and including the
    /// marathon default to Road; everything else (trail, ultra, no race)
    /// stays on Trail.
    var effectiveRunningTerrain: TerrainType {
        if runningTerrainUserPicked { return runningTerrain }
        let isRoadByType = raceType == .road
        let isRoadByHeuristic = raceElevationGainM < 100 && raceDistanceKm > 0 && raceDistanceKm <= 42.195
        return (isRoadByType || isRoadByHeuristic) ? .road : .trail
    }

    var uphillDuration: UphillDuration? = nil
    var treadmillMaxIncline: TreadmillIncline? = nil
    var intervalFocus: IntervalFocus = .mixed

    var isShortRoadRace: Bool {
        raceElevationGainM < 100 && raceDistanceKm < 42.195 && raceDistanceKm > 0
    }

    /// Whether the target-time picker should expose a seconds field.
    /// Road races up to marathon (inclusive) need second precision
    /// the gap between e.g. 36:01 and 36:55 in a 10K shifts target
    /// paces by ~10 sec/km. For trail/ultra A-races minute precision
    /// is sufficient (and seconds would be noise relative to race-day
    /// variability).
    var showsTargetTimeSeconds: Bool {
        let isRoadByType = raceType == .road
        let isRoadByHeuristic = raceElevationGainM < 100 && raceDistanceKm > 0
        let isRoad = isRoadByType || isRoadByHeuristic
        return isRoad && raceDistanceKm > 0 && raceDistanceKm <= 42.195
    }

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        initialFirstName: String? = nil,
        initialLastName: String? = nil
    ) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.initialFirstName = initialFirstName
        self.initialLastName = initialLastName
        if let name = initialFirstName, !name.isEmpty {
            self.firstName = name
        }
        if let name = initialLastName, !name.isEmpty {
            self.lastName = name
        }
    }

    // MARK: - Personal Bests Helpers

    /// Whether the user has entered at least one PB.
    var hasAnyPB: Bool {
        !buildCurrentPBs().isEmpty
    }

    /// Builds PB entries from the current form values (only non-zero entries).
    func buildCurrentPBs() -> [PersonalBest] {
        var bests: [PersonalBest] = []
        let entries: [(PersonalBestDistance, Int, Int, Int, Date)] = [
            (.fiveK, pb5kHours, pb5kMinutes, pb5kSeconds, pb5kDate),
            (.tenK, pb10kHours, pb10kMinutes, pb10kSeconds, pb10kDate),
            (.halfMarathon, pbHalfHours, pbHalfMinutes, pbHalfSeconds, pbHalfDate),
            (.marathon, pbMarathonHours, pbMarathonMinutes, pbMarathonSeconds, pbMarathonDate),
        ]
        for (distance, h, m, s, date) in entries {
            let total = TimeInterval(h * 3600 + m * 60 + s)
            let minAllowed = Self.worldRecordMinSeconds(for: distance)
            if total > 0, total >= TimeInterval(minAllowed) {
                bests.append(PersonalBest(id: UUID(), distance: distance, timeSeconds: total, date: date))
            }
        }
        return bests
    }

    /// Minimum allowed time per distance (world record minus 60 seconds).
    static func worldRecordMinSeconds(for distance: PersonalBestDistance) -> Int {
        switch distance {
        case .fiveK: return 695          // WR 12:35 - 60s
        case .tenK: return 1511          // WR 26:11 - 60s
        case .halfMarathon: return 3391  // WR 57:31 - 60s
        case .marathon: return 7175      // WR 2:00:35 - 60s
        }
    }

    // MARK: - Validation
    // Steps: 0=Experience, 1=RunningHistory, 2=PersonalBests, 3=AboutYou,
    //        4=BodyMetrics, 5=HeartRate, 6=InjuryStrength, 7=RaceName,
    //        8=RaceProfile, 9=GoalTraining, 10=UphillDetails, 11=VolumePreview, 12=Complete

    /// Whether the uphill details step is relevant (elevation-heavy race or VG training needed).
    var needsUphillDetailsStep: Bool {
        raceElevationGainM > 500 || hasNoRace
    }

    var trainingDurationValidation: TrainingDurationValidation? {
        guard !hasNoRace else { return nil }
        return TrainingDurationValidator.validate(
            distanceKm: raceDistanceKm,
            elevationGainM: raceElevationGainM,
            raceDate: raceDate,
            experienceLevel: experienceLevel ?? .beginner
        )
    }

    var canAdvance: Bool {
        switch currentStep {
        case 0: experienceLevel != nil
        case 1: isNewRunner || (weeklyVolumeKm > 0 && longestRunKm > 0)
        case 2: true // Personal bests optional
        case 3: isAboutYouValid
        case 4: isBodyMetricsValid
        case 5: true // Heart rate has sane defaults
        case 6: isInjuryStrengthValid
        case 7: hasNoRace || isRaceNameValid
        case 8: hasNoRace || (isRaceProfileValid && (trainingDurationValidation?.isSufficient ?? true))
        case 9: hasNoRace ? true : isGoalTrainingValid
        case 10: isUphillDetailsValid
        case 11: true // Volume preview
        default: true
        }
    }

    private var isAboutYouValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && {
                let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
                return (16...100).contains(age)
            }()
    }

    private var isInjuryStrengthValid: Bool {
        guard painFrequency != nil else { return false }
        guard injuryCountLastYear != nil else { return false }
        guard strengthTrainingPreference != nil else { return false }
        if strengthTrainingPreference == .yes {
            return strengthTrainingLocation != nil
        }
        return true
    }

    private var isUphillDetailsValid: Bool {
        // If athlete has outdoor hills, they must specify uphill duration
        if verticalGainEnvironment != .treadmill && uphillDuration == nil {
            return false
        }
        // If athlete uses treadmill, they must specify max incline
        if (verticalGainEnvironment == .treadmill || verticalGainEnvironment == .mixed)
            && treadmillMaxIncline == nil {
            return false
        }
        return true
    }

    private var isBodyMetricsValid: Bool {
        (30...200).contains(weightKg) && (100...250).contains(heightCm)
    }

    private var isRaceNameValid: Bool {
        !raceName.trimmingCharacters(in: .whitespaces).isEmpty && raceDate > Date.now
    }

    private var isRaceProfileValid: Bool {
        raceDistanceKm > 0 && raceElevationGainM >= 0 && raceElevationLossM >= 0
    }

    private var isGoalTrainingValid: Bool {
        if raceGoalType == .targetTime {
            guard raceTargetTimeHours > 0 || raceTargetTimeMinutes > 0 else { return false }
        }
        if raceGoalType == .targetRanking {
            guard raceTargetRanking > 0 else { return false }
        }
        return true
    }

    // MARK: - Navigation

    func advance() {
        guard canAdvance, currentStep < totalSteps - 1 else { return }
        error = nil
        if hasNoRace && currentStep == 7 {
            currentStep = 9 // Skip race profile (8), go to goal/training
        } else if hasNoRace && currentStep == 9 {
            currentStep = 12 // No race → skip uphill, volume preview → complete
        } else if currentStep == 9 && !needsUphillDetailsStep {
            currentStep = 11 // Skip uphill details (10), go to volume preview
        } else {
            currentStep += 1
        }
    }

    func goBack() {
        guard currentStep > 0 else { return }
        error = nil
        if hasNoRace && currentStep == 12 {
            currentStep = 9 // No race → back to goal/training
        } else if hasNoRace && currentStep == 9 {
            currentStep = 7 // Back to race name
        } else if currentStep == 11 && !needsUphillDetailsStep {
            currentStep = 9 // Back to goal/training (skipped uphill)
        } else {
            currentStep -= 1
        }
    }

    // MARK: - Save

    func completeOnboarding() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        do {
            let athlete = buildAthlete()
            try await athleteRepository.saveAthlete(athlete)
            if !hasNoRace {
                let race = buildRace()
                try await raceRepository.saveRace(race)
            }
            savedAthleteId = athlete.id
            isCompleted = true
            Logger.app.info("Onboarding completed for \(athlete.firstName)")
        } catch {
            self.error = "Failed to save your profile. Please try again."
            Logger.app.error("Onboarding save failed: \(error)")
        }

        isSaving = false
    }

    private func buildAthlete() -> Athlete {
        let pbs = buildPersonalBests()
        let trailPbs = buildTrailPBs()
        let metrics = PerformanceEstimator.deriveMetrics(from: pbs)
        return Athlete(
            id: UUID(),
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            weightKg: weightKg,
            heightCm: heightCm,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            experienceLevel: experienceLevel ?? .beginner,
            weeklyVolumeKm: isNewRunner ? 0 : weeklyVolumeKm,
            longestRunKm: isNewRunner ? 0 : longestRunKm,
            preferredUnit: preferredUnit,
            personalBests: pbs,
            trailPersonalBests: trailPbs,
            trainingPhilosophy: trainingPhilosophy,
            trainingFocus: trainingFocus,
            preferredRunsPerWeek: preferredRunsPerWeek,
            weightGoal: weightGoal,
            biologicalSex: biologicalSex,
            verticalGainEnvironment: verticalGainEnvironment,
            painFrequency: painFrequency ?? .never,
            injuryCountLastYear: injuryCountLastYear ?? .none,
            hasRecentInjury: hasRecentInjury,
            strengthTrainingPreference: strengthTrainingPreference ?? .no,
            strengthTrainingLocation: strengthTrainingLocation ?? .home,
            runningTerrain: effectiveRunningTerrain,
            uphillDuration: uphillDuration,
            treadmillMaxIncline: treadmillMaxIncline,
            intervalFocus: intervalFocus,
            vo2max: metrics?.vo2max,
            vmaKmh: metrics?.vmaKmh,
            thresholdPace60MinPerKm: metrics?.thresholdPace60MinPerKm,
            thresholdPace30MinPerKm: metrics?.thresholdPace30MinPerKm
        )
    }

    private func buildPersonalBests() -> [PersonalBest] {
        let known = buildCurrentPBs()
        guard !known.isEmpty else { return [] }
        // Adjust old PBs assuming slight improvement from training
        let adjusted = PerformanceEstimator.adjustPBsForTrainingProgress(known)
        // Deduce missing PBs from adjusted ones using Riegel formula
        return PerformanceEstimator.deduceMissingPBs(from: adjusted)
    }

    // MARK: - Volume Preview

    struct VolumeEstimate: Identifiable {
        let runsPerWeek: Int
        let weeklyKmMin: Int
        let weeklyKmMax: Int
        let isRecommended: Bool
        var id: Int { runsPerWeek }
    }

    var volumePreviewData: [VolumeEstimate] {
        let experience = experienceLevel ?? .beginner
        let effectiveKm = raceDistanceKm + raceElevationGainM / 100.0
        let totalWeeks = max(Date.now.weeksBetween(raceDate), 8)
        let raceGoal = buildRaceGoal()

        let raceDuration: TimeInterval = {
            if case .targetTime(let time) = raceGoal { return time }
            let paceMinPerKm: Double = switch experience {
            case .elite:        8.0
            case .advanced:     9.0
            case .intermediate: 10.0
            case .beginner:     12.0
            }
            return effectiveKm * paceMinPerKm * 60
        }()

        let phases = PhaseDistributor.distribute(
            totalWeeks: totalWeeks,
            experience: experience
        )
        let skeletons = WeekSkeletonBuilder.build(
            raceDate: raceDate,
            phases: phases
        )

        let currentVolume = isNewRunner ? 0 : weeklyVolumeKm
        let avgPaceSecPerKm: Double = 390
        let recommendedRuns = recommendedRunsPerWeek(
            experience: experience,
            effectiveKm: effectiveKm
        )

        // Route to the calculator that drives the actual plan so the
        // preview matches what the user will get. Road races (≤ marathon,
        // low elevation gain) use RoadVolumeCalculator; everything else
        // uses the trail LongRunCurveCalculator.
        let isRoadRace: Bool = {
            if raceType == .road { return true }
            return raceElevationGainM < 100
                && raceDistanceKm > 0
                && raceDistanceKm <= 42.195
        }()

        var estimates: [VolumeEstimate] = []
        let weeksToCheck = min(4, skeletons.count)

        if isRoadRace {
            // RoadVolumeCalculator returns the full block; we sample the
            // first month and re-run per frequency option since the total
            // now scales with preferredRunsPerWeek.
            let taperProfile = TaperProfile.forRoadRace(distanceKm: raceDistanceKm)
            let stubAthlete = volumePreviewStubAthlete(experience: experience)

            for runs in 3...7 {
                let volumes = RoadVolumeCalculator.calculate(
                    skeletons: skeletons,
                    athlete: stubAthlete,
                    raceDistanceKm: raceDistanceKm,
                    taperProfile: taperProfile,
                    raceGoal: raceGoal,
                    preferredRunsPerWeek: runs
                )
                let firstMonth = volumes.prefix(weeksToCheck).map(\.targetVolumeKm)
                let minKm = Int((firstMonth.min() ?? 0).rounded())
                let maxKm = Int((firstMonth.max() ?? 0).rounded())

                estimates.append(VolumeEstimate(
                    runsPerWeek: runs,
                    weeklyKmMin: minKm,
                    weeklyKmMax: maxKm,
                    isRecommended: runs == recommendedRuns
                ))
            }
        } else {
            for runs in 3...7 {
                var weekKms: [Double] = []
                for i in 0..<weeksToCheck {
                    let skeleton = skeletons[i]
                    let durations = LongRunCurveCalculator.durations(
                        weekIndex: i,
                        totalWeeks: totalWeeks,
                        phase: skeleton.phase,
                        isRecoveryWeek: skeleton.isRecoveryWeek,
                        experience: experience,
                        philosophy: trainingPhilosophy,
                        raceGoal: raceGoal,
                        raceDurationSeconds: raceDuration,
                        raceEffectiveKm: effectiveKm,
                        preferredRunsPerWeek: runs,
                        currentWeeklyVolumeKm: currentVolume
                    )
                    weekKms.append(durations.totalSeconds / avgPaceSecPerKm)
                }

                let minKm = Int((weekKms.min() ?? 0).rounded())
                let maxKm = Int((weekKms.max() ?? 0).rounded())

                estimates.append(VolumeEstimate(
                    runsPerWeek: runs,
                    weeklyKmMin: minKm,
                    weeklyKmMax: maxKm,
                    isRecommended: runs == recommendedRuns
                ))
            }
        }

        return estimates
    }

    /// Builds a minimal Athlete instance just for the preview pass through
    /// RoadVolumeCalculator. The calculator reads experience, weeklyVolumeKm,
    /// longestRunKm, trainingPhilosophy, age, and pain/injury flags. The rest
    /// of the Athlete fields aren't touched by the volume math.
    private func volumePreviewStubAthlete(experience: ExperienceLevel) -> Athlete {
        Athlete(
            id: UUID(),
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            weightKg: weightKg,
            heightCm: heightCm,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            experienceLevel: experience,
            weeklyVolumeKm: isNewRunner ? 0 : weeklyVolumeKm,
            longestRunKm: isNewRunner ? 0 : longestRunKm,
            preferredUnit: preferredUnit,
            trainingPhilosophy: trainingPhilosophy,
            trainingFocus: trainingFocus,
            preferredRunsPerWeek: preferredRunsPerWeek,
            weightGoal: weightGoal,
            biologicalSex: biologicalSex,
            painFrequency: painFrequency ?? .never,
            injuryCountLastYear: injuryCountLastYear ?? .none,
            hasRecentInjury: hasRecentInjury
        )
    }

    /// Smart recommendation based on athlete profile, race, philosophy, and injury risk.
    private func recommendedRunsPerWeek(
        experience: ExperienceLevel,
        effectiveKm: Double
    ) -> Int {
        let raceCategory = RaceCategory.from(effectiveDistanceKm: effectiveKm)

        // Base recommendation per experience level
        var base: Int = switch experience {
        case .beginner:     3
        case .intermediate: 4
        case .advanced:     5
        case .elite:        5
        }

        // Race distance adjustments
        switch raceCategory {
        case .trail, .fiftyK:
            break // no change for shorter races
        case .hundredK:
            base += 1
        case .hundredMiles, .ultraLong:
            base += 1
        }

        // Philosophy adjustments
        switch trainingPhilosophy {
        case .enjoyment:    base -= 1
        case .balanced:     break
        case .performance:  base += 1
        }

        // Injury risk: reduce if pain is frequent or multiple recent injuries
        if painFrequency == .often || injuryCountLastYear == .threeOrMore {
            base -= 1
        } else if painFrequency == .sometimes && injuryCountLastYear != .none {
            base -= 1
        }

        // New runner cap
        if isNewRunner { base = min(base, 4) }

        // Experience caps
        switch experience {
        case .beginner:     base = min(base, 4)
        case .intermediate: base = min(base, 5)
        case .advanced:     base = min(base, 6)
        case .elite:        break
        }

        return max(3, min(base, 7))
    }

    private func buildRace() -> Race {
        var race = Race(
            id: UUID(),
            name: raceName.trimmingCharacters(in: .whitespaces),
            date: raceDate,
            distanceKm: raceDistanceKm,
            elevationGainM: raceElevationGainM,
            elevationLossM: raceElevationLossM,
            priority: .aRace,
            goalType: buildRaceGoal(),
            checkpoints: [],
            terrainDifficulty: raceTerrainDifficulty,
            raceType: raceType
        )
        // T8: forward altitude + pole flags from the known-race
        // pre-population. Plain memberwise init doesn't support the
        // optional fields without ordering rework, so set them after.
        race.maxElevationM = raceMaxElevationM
        race.polesAllowed = racePolesAllowed
        return race
    }

    // MARK: - Race-day projection hint

    /// A quick, dependency-light finish-time projection used only to ground
    /// goal-setting in what the athlete is likely capable of BY RACE DAY
    /// (after training), not just today. Reuses the same `buildAthlete()`/
    /// `buildRace()` used at save time, so it works with whatever profile
    /// data has been entered so far — degrades gracefully to the
    /// experience-level fallback when PBs haven't been entered yet, same
    /// as the real Day-0 estimate elsewhere in the app.
    func projectedRaceDayEstimate() async -> TimeInterval? {
        guard !hasNoRace, raceDistanceKm > 0 else { return nil }
        let athlete = buildAthlete()
        let race = buildRace()
        do {
            let estimate = try await FinishTimeEstimator().execute(
                athlete: athlete,
                race: race,
                recentRuns: [],
                currentFitness: nil,
                pastRaceCalibrations: [],
                weatherImpact: nil
            )
            let secs = race.date.timeIntervalSinceNow
            let weeksToRace = secs > 0 ? max(0, Int((secs / 86400 / 7).rounded())) : 0
            let intensityMultiplier = FinishTimeEstimator.trainingIntensityMultiplier(
                philosophy: athlete.trainingPhilosophy, sessionsPerWeek: athlete.preferredRunsPerWeek
            )
            return FinishTimeEstimator.projectedRaceDayEstimate(
                optimisticTime: estimate.optimisticTime,
                expectedTime: estimate.expectedTime,
                weeksToRace: weeksToRace,
                intensityMultiplier: intensityMultiplier
            )
        } catch {
            return nil
        }
    }

    private func buildRaceGoal() -> RaceGoal {
        switch raceGoalType {
        case .finish:
            return .finish
        case .targetTime:
            // Include seconds component when the UI exposes the field
            // (road race ≤ marathon). For longer trail/ultra goals the
            // seconds picker stays hidden so raceTargetTimeSeconds is
            // always 0 → no impact.
            let totalSeconds = raceTargetTimeHours * 3600
                + raceTargetTimeMinutes * 60
                + raceTargetTimeSeconds
            return .targetTime(TimeInterval(totalSeconds))
        case .targetRanking:
            return .targetRanking(raceTargetRanking)
        }
    }
}
