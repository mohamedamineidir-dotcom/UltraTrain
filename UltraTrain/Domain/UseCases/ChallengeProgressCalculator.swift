import Foundation

enum ChallengeProgressCalculator {

    struct ChallengeProgress: Equatable, Sendable {
        let enrollment: ChallengeEnrollment
        let definition: ChallengeDefinition
        let currentValue: Double
        let targetValue: Double

        var progressFraction: Double {
            guard targetValue > 0 else { return 0 }
            return min(currentValue / targetValue, 1.0)
        }

        var isComplete: Bool {
            currentValue >= targetValue
        }
    }

    // MARK: - Challenge Progress

    static func computeProgress(
        enrollment: ChallengeEnrollment,
        definition: ChallengeDefinition,
        runs: [CompletedRun]
    ) -> ChallengeProgress {
        let endDate = Calendar.current.date(
            byAdding: .day, value: definition.duration.days, to: enrollment.startDate
        ) ?? enrollment.startDate
        let runsInRange = runs.filter { $0.date >= enrollment.startDate && $0.date < endDate }

        let currentValue: Double
        switch definition.type {
        case .distance:
            currentValue = runsInRange.reduce(0) { $0 + $1.distanceKm }
        case .elevation:
            currentValue = runsInRange.reduce(0) { $0 + $1.elevationGainM }
        case .consistency:
            currentValue = computeConsistency(runs: runsInRange, duration: definition.duration)
        case .streak:
            currentValue = Double(computeStreakInRange(runs: runsInRange, from: enrollment.startDate))
        }

        return ChallengeProgress(
            enrollment: enrollment,
            definition: definition,
            currentValue: currentValue,
            targetValue: definition.targetValue
        )
    }

    // MARK: - Streak

    static func computeCurrentStreak(from runs: [CompletedRun]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(runs.map { calendar.startOfDay(for: $0.date) })
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date.now)

        if !uniqueDays.contains(checkDate) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            if uniqueDays.contains(yesterday) {
                checkDate = yesterday
            } else {
                return 0
            }
        }

        while uniqueDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    static func computeLongestStreak(from runs: [CompletedRun]) -> Int {
        let calendar = Calendar.current
        let sortedDays = Set(runs.map { calendar.startOfDay(for: $0.date) }).sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<sortedDays.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1])
            if expected == sortedDays[i] {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    // MARK: - Helpers

    private static func computeConsistency(runs: [CompletedRun], duration: ChallengeDuration) -> Double {
        let calendar = Calendar.current
        guard !runs.isEmpty else { return 0 }

        let weekCount = max(1, duration.days / 7)
        let sortedRuns = runs.sorted { $0.date < $1.date }
        guard let earliest = sortedRuns.first?.date else { return 0 }

        var weeksMetTarget = 0
        for weekIndex in 0..<weekCount {
            guard let weekStart = calendar.date(byAdding: .day, value: weekIndex * 7, to: earliest),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let weekRunDays = Set(
                sortedRuns
                    .filter { $0.date >= weekStart && $0.date < weekEnd }
                    .map { calendar.startOfDay(for: $0.date) }
            ).count
            if weekRunDays > 0 {
                weeksMetTarget += 1
            }
        }

        return Double(weeksMetTarget)
    }

    private static func computeStreakInRange(runs: [CompletedRun], from startDate: Date) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(runs.map { calendar.startOfDay(for: $0.date) })
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date.now)

        while checkDate <= today {
            if uniqueDays.contains(checkDate) {
                streak += 1
            } else {
                break
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = next
        }

        return streak
    }
}
