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
    let totalSteps = 10
    var isCompleted = false
    var isSaving = false
    var error: String?
    private(set) var savedAthleteId: UUID?
    var initialFirstName: String?

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
    var preferredRunsPerWeek: Int = 4
    var raceName = ""
    var raceDate = Calendar.current.date(byAdding: .month, value: 6, to: .now)!
    var raceDistanceKm: Double = 50
    var raceElevationGainM: Double = 2000
    var raceElevationLossM: Double = 2000
    var raceGoalType: RaceGoalSelection = .finish
    var raceTargetTimeHours: Int = 10
    var raceTargetTimeMinutes: Int = 0
    var raceTargetRanking: Int = 50
    var raceTerrainDifficulty: TerrainDifficulty = .moderate

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        initialFirstName: String? = nil
    ) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.initialFirstName = initialFirstName
        if let name = initialFirstName, !name.isEmpty {
            self.firstName = name
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
    //        4=BodyMetrics, 5=HeartRate, 6=RaceName, 7=RaceProfile,
    //        8=GoalTraining, 9=Complete

    var canAdvance: Bool {
        switch currentStep {
        case 0: experienceLevel != nil
        case 1: isNewRunner || (weeklyVolumeKm > 0 && longestRunKm > 0)
        case 2: true // Personal bests optional
        case 3: isAboutYouValid
        case 4: isBodyMetricsValid
        case 5: true // Heart rate has sane defaults
        case 6: isRaceNameValid
        case 7: isRaceProfileValid
        case 8: isGoalTrainingValid
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
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 0 else { return }
        error = nil
        currentStep -= 1
    }

    // MARK: - Save

    func completeOnboarding() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        do {
            let athlete = buildAthlete()
            let race = buildRace()
            try await athleteRepository.saveAthlete(athlete)
            try await raceRepository.saveRace(race)
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
            trainingPhilosophy: trainingPhilosophy,
            preferredRunsPerWeek: preferredRunsPerWeek,
            weightGoal: weightGoal,
            biologicalSex: biologicalSex,
            vo2max: metrics?.vo2max,
            vmaKmh: metrics?.vmaKmh,
            thresholdPace60MinPerKm: metrics?.thresholdPace60MinPerKm,
            thresholdPace30MinPerKm: metrics?.thresholdPace30MinPerKm
        )
    }

    private func buildPersonalBests() -> [PersonalBest] {
        let known = buildCurrentPBs()
        guard !known.isEmpty else { return [] }
        // Deduce missing PBs from entered ones using Riegel formula
        return PerformanceEstimator.deduceMissingPBs(from: known)
    }

    private func buildRace() -> Race {
        Race(
            id: UUID(),
            name: raceName.trimmingCharacters(in: .whitespaces),
            date: raceDate,
            distanceKm: raceDistanceKm,
            elevationGainM: raceElevationGainM,
            elevationLossM: raceElevationLossM,
            priority: .aRace,
            goalType: buildRaceGoal(),
            checkpoints: [],
            terrainDifficulty: raceTerrainDifficulty
        )
    }

    private func buildRaceGoal() -> RaceGoal {
        switch raceGoalType {
        case .finish:
            return .finish
        case .targetTime:
            let seconds = TimeInterval(raceTargetTimeHours * 3600 + raceTargetTimeMinutes * 60)
            return .targetTime(seconds)
        case .targetRanking:
            return .targetRanking(raceTargetRanking)
        }
    }
}
