import Foundation
import os

@Observable
@MainActor
final class ChallengesViewModel {

    // MARK: - Dependencies

    private let challengeRepository: any ChallengeRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository

    // MARK: - State

    var activeProgress: [ChallengeProgressCalculator.ChallengeProgress] = []
    var availableChallenges: [ChallengeDefinition] = []
    var completedEnrollments: [ChallengeEnrollment] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        challengeRepository: any ChallengeRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        self.challengeRepository = challengeRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            let enrollments = try await challengeRepository.getEnrollments()
            let athlete = try await athleteRepository.getAthlete()
            guard let athlete else {
                isLoading = false
                return
            }

            let runs = try await runRepository.getRuns(for: athlete.id)

            var progressList: [ChallengeProgressCalculator.ChallengeProgress] = []
            var newlyCompleted: [ChallengeEnrollment] = []
            let activeEnrollments = enrollments.filter { $0.status == .active }

            for enrollment in activeEnrollments {
                guard let definition = ChallengeLibrary.definition(for: enrollment.challengeDefinitionId) else {
                    continue
                }
                let progress = ChallengeProgressCalculator.computeProgress(
                    enrollment: enrollment,
                    definition: definition,
                    runs: runs
                )
                if progress.isComplete {
                    var updated = enrollment
                    updated.status = .completed
                    updated.completedDate = .now
                    try await challengeRepository.updateEnrollment(updated)
                    newlyCompleted.append(updated)
                } else {
                    progressList.append(progress)
                }
            }

            activeProgress = progressList
            completedEnrollments = enrollments.filter { $0.status == .completed } + newlyCompleted

            let activeDefinitionIds = Set(activeEnrollments.map(\.challengeDefinitionId))
            let completedDefinitionIds = Set(completedEnrollments.map(\.challengeDefinitionId))
            let enrolledIds = activeDefinitionIds.union(completedDefinitionIds)
            availableChallenges = ChallengeLibrary.all.filter { !enrolledIds.contains($0.id) }

            currentStreak = ChallengeProgressCalculator.computeCurrentStreak(from: runs)
            longestStreak = ChallengeProgressCalculator.computeLongestStreak(from: runs)
        } catch {
            self.error = error.localizedDescription
            Logger.challenges.error("Failed to load challenges: \(error)")
        }

        isLoading = false
    }

    // MARK: - Actions

    func startChallenge(_ definition: ChallengeDefinition) async {
        do {
            let enrollment = ChallengeEnrollment(
                id: UUID(),
                challengeDefinitionId: definition.id,
                startDate: .now,
                status: .active
            )
            try await challengeRepository.saveEnrollment(enrollment)
            await load()
        } catch {
            self.error = error.localizedDescription
            Logger.challenges.error("Failed to start challenge: \(error)")
        }
    }

    func abandonChallenge(_ enrollmentId: UUID) async {
        do {
            try await challengeRepository.deleteEnrollment(id: enrollmentId)
            await load()
        } catch {
            self.error = error.localizedDescription
            Logger.challenges.error("Failed to abandon challenge: \(error)")
        }
    }
}
