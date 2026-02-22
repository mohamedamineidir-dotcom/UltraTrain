import Foundation
import os

@Observable
@MainActor
final class AchievementsViewModel {
    private let achievementRepository: any AchievementRepository
    private let runRepository: any RunRepository
    private let challengeRepository: any ChallengeRepository
    private let raceRepository: any RaceRepository

    var unlockedIds: Set<String> = []
    var unlockedAchievements: [UnlockedAchievement] = []
    var selectedCategory: AchievementCategory?
    var isLoading = false
    var error: String?

    var displayedAchievements: [Achievement] {
        let all = AchievementLibrary.all
        guard let category = selectedCategory else { return all }
        return all.filter { $0.category == category }
    }

    var unlockedCount: Int { unlockedIds.count }
    var totalCount: Int { AchievementLibrary.all.count }

    init(
        achievementRepository: any AchievementRepository,
        runRepository: any RunRepository,
        challengeRepository: any ChallengeRepository,
        raceRepository: any RaceRepository
    ) {
        self.achievementRepository = achievementRepository
        self.runRepository = runRepository
        self.challengeRepository = challengeRepository
        self.raceRepository = raceRepository
    }

    func load() async {
        isLoading = true
        do {
            unlockedAchievements = try await achievementRepository.getUnlockedAchievements()
            unlockedIds = Set(unlockedAchievements.map(\.achievementId))
            await evaluateNewAchievements()
        } catch {
            self.error = error.localizedDescription
            Logger.achievements.error("Failed to load achievements: \(error)")
        }
        isLoading = false
    }

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedIds.contains(achievement.id)
    }

    func unlockedDate(for achievement: Achievement) -> Date? {
        unlockedAchievements.first { $0.achievementId == achievement.id }?.unlockedDate
    }

    private func evaluateNewAchievements() async {
        do {
            let races = try await raceRepository.getRaces()
            let enrollments = try await challengeRepository.getEnrollments()
            let runs = try await runRepository.getRecentRuns(limit: 10000)
            let records = PersonalRecordCalculator.computeAll(from: runs)

            let newlyUnlocked = AchievementEvaluator.evaluate(
                runs: runs,
                enrollments: enrollments,
                races: races,
                personalRecords: records,
                alreadyUnlocked: unlockedIds
            )

            for achievement in newlyUnlocked {
                try await achievementRepository.saveUnlocked(achievement)
                unlockedIds.insert(achievement.achievementId)
                unlockedAchievements.append(achievement)
            }
        } catch {
            Logger.achievements.error("Failed to evaluate achievements: \(error)")
        }
    }
}
