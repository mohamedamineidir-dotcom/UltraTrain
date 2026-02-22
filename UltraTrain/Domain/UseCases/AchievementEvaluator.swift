import Foundation

enum AchievementEvaluator {

    static func evaluate(
        runs: [CompletedRun],
        enrollments: [ChallengeEnrollment],
        races: [Race],
        personalRecords: [PersonalRecord],
        alreadyUnlocked: Set<String>
    ) -> [UnlockedAchievement] {
        let now = Date.now
        var newlyUnlocked: [UnlockedAchievement] = []

        let totalDistance = runs.reduce(0.0) { $0 + $1.distanceKm }
        let totalElevation = runs.reduce(0.0) { $0 + $1.elevationGainM }
        let totalRunCount = runs.count
        let completedRaces = races.filter { $0.isCompleted }
        let completedChallenges = enrollments.filter { $0.status == .completed }
        let maxSingleDistance = runs.map(\.distanceKm).max() ?? 0
        let maxSingleElevation = runs.map(\.elevationGainM).max() ?? 0
        let currentStreak = calculateCurrentStreak(runs: runs)

        for achievement in AchievementLibrary.all {
            guard !alreadyUnlocked.contains(achievement.id) else { continue }

            let met: Bool
            switch achievement.requirement {
            case .totalDistanceKm(let km):
                met = totalDistance >= km
            case .totalElevationM(let m):
                met = totalElevation >= m
            case .singleRunDistanceKm(let km):
                met = maxSingleDistance >= km
            case .singleRunElevationM(let m):
                met = maxSingleElevation >= m
            case .totalRuns(let count):
                met = totalRunCount >= count
            case .streakDays(let days):
                met = currentStreak >= days
            case .completedRace:
                met = !completedRaces.isEmpty
            case .completedRaces(let count):
                met = completedRaces.count >= count
            case .completedChallenge(let count):
                met = completedChallenges.count >= count
            case .personalRecord:
                met = !personalRecords.isEmpty
            }

            if met {
                newlyUnlocked.append(UnlockedAchievement(
                    id: UUID(),
                    achievementId: achievement.id,
                    unlockedDate: now
                ))
            }
        }

        return newlyUnlocked
    }

    private static func calculateCurrentStreak(runs: [CompletedRun]) -> Int {
        guard !runs.isEmpty else { return 0 }
        let calendar = Calendar.current
        let runDays = Set(runs.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var day = calendar.startOfDay(for: Date.now)

        while runDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }
}
