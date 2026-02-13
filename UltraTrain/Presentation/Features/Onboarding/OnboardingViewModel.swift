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
    let totalSteps = 6
    var isCompleted = false
    var isSaving = false
    var error: String?

    // MARK: - Step 1: Experience

    var experienceLevel: ExperienceLevel?
    var preferredUnit: UnitPreference = .metric

    // MARK: - Step 2: Running History

    var weeklyVolumeKm: Double = 30
    var longestRunKm: Double = 15
    var isNewRunner = false

    // MARK: - Step 3: Physical Data

    var firstName = ""
    var lastName = ""
    var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: .now)!
    var weightKg: Double = 70
    var heightCm: Double = 175
    var restingHeartRate: Int = 60
    var maxHeartRate: Int = 185

    // MARK: - Step 4: Race Goal

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

    init(athleteRepository: any AthleteRepository, raceRepository: any RaceRepository) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
    }

    // MARK: - Validation

    var canAdvance: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            return experienceLevel != nil
        case 2:
            return isNewRunner || (weeklyVolumeKm > 0 && longestRunKm > 0)
        case 3:
            return isPhysicalDataValid
        case 4:
            return isRaceGoalValid
        default:
            return true
        }
    }

    private var isPhysicalDataValid: Bool {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard !lastName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
        guard age >= 16, age <= 100 else { return false }
        guard (30...200).contains(weightKg) else { return false }
        guard (100...250).contains(heightCm) else { return false }
        guard (30...120).contains(restingHeartRate) else { return false }
        guard (120...230).contains(maxHeartRate) else { return false }
        guard maxHeartRate > restingHeartRate else { return false }
        return true
    }

    private var isRaceGoalValid: Bool {
        guard !raceName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard raceDate > Date.now else { return false }
        guard raceDistanceKm > 0 else { return false }
        guard raceElevationGainM >= 0 else { return false }
        guard raceElevationLossM >= 0 else { return false }
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
            isCompleted = true
            Logger.app.info("Onboarding completed for \(athlete.firstName)")
        } catch {
            self.error = "Failed to save your profile. Please try again."
            Logger.app.error("Onboarding save failed: \(error)")
        }

        isSaving = false
    }

    private func buildAthlete() -> Athlete {
        Athlete(
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
            preferredUnit: preferredUnit
        )
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
