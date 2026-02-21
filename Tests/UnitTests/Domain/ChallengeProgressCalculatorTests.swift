import Foundation
import Testing
@testable import UltraTrain

@Suite("ChallengeProgressCalculator Tests")
struct ChallengeProgressCalculatorTests {

    // MARK: - Helpers

    private func makeRun(date: Date, distanceKm: Double = 10, elevationGainM: Double = 200) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 0,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    private func makeEnrollment(definitionId: String, startDate: Date) -> ChallengeEnrollment {
        ChallengeEnrollment(
            id: UUID(),
            challengeDefinitionId: definitionId,
            startDate: startDate,
            status: .active
        )
    }

    // MARK: - Distance Progress

    @Test("Distance challenge sums km in date range")
    func distanceProgress() {
        let definition = ChallengeLibrary.definition(for: "dist_100km_month")!
        let start = Date.now.addingTimeInterval(-86400 * 10)
        let enrollment = makeEnrollment(definitionId: definition.id, startDate: start)

        let runs = [
            makeRun(date: start.addingTimeInterval(86400), distanceKm: 15),
            makeRun(date: start.addingTimeInterval(86400 * 2), distanceKm: 20),
            makeRun(date: start.addingTimeInterval(-86400), distanceKm: 50), // before start
        ]

        let progress = ChallengeProgressCalculator.computeProgress(
            enrollment: enrollment, definition: definition, runs: runs
        )

        #expect(progress.currentValue == 35)
        #expect(progress.targetValue == 100)
    }

    // MARK: - Elevation Progress

    @Test("Elevation challenge sums D+ in date range")
    func elevationProgress() {
        let definition = ChallengeLibrary.definition(for: "elev_2000m_month")!
        let start = Date.now.addingTimeInterval(-86400 * 5)
        let enrollment = makeEnrollment(definitionId: definition.id, startDate: start)

        let runs = [
            makeRun(date: start.addingTimeInterval(86400), elevationGainM: 500),
            makeRun(date: start.addingTimeInterval(86400 * 3), elevationGainM: 800),
        ]

        let progress = ChallengeProgressCalculator.computeProgress(
            enrollment: enrollment, definition: definition, runs: runs
        )

        #expect(progress.currentValue == 1300)
        #expect(progress.targetValue == 2000)
    }

    // MARK: - Progress Fraction

    @Test("Progress fraction caps at 1.0")
    func progressFractionCaps() {
        let definition = ChallengeLibrary.definition(for: "dist_50km_month")!
        let start = Date.now.addingTimeInterval(-86400 * 5)
        let enrollment = makeEnrollment(definitionId: definition.id, startDate: start)

        let runs = [makeRun(date: start.addingTimeInterval(86400), distanceKm: 100)]

        let progress = ChallengeProgressCalculator.computeProgress(
            enrollment: enrollment, definition: definition, runs: runs
        )

        #expect(progress.progressFraction == 1.0)
        #expect(progress.isComplete)
    }

    // MARK: - Is Complete

    @Test("isComplete returns true when target reached")
    func isCompleteWhenTargetReached() {
        let definition = ChallengeLibrary.definition(for: "dist_50km_month")!
        let start = Date.now.addingTimeInterval(-86400 * 5)
        let enrollment = makeEnrollment(definitionId: definition.id, startDate: start)

        let runs = [makeRun(date: start.addingTimeInterval(86400), distanceKm: 50)]

        let progress = ChallengeProgressCalculator.computeProgress(
            enrollment: enrollment, definition: definition, runs: runs
        )

        #expect(progress.isComplete)
    }

    // MARK: - Current Streak

    @Test("Current streak counts consecutive days")
    func currentStreakConsecutive() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let runs = (0..<5).map { dayOffset in
            makeRun(date: calendar.date(byAdding: .day, value: -dayOffset, to: today)!)
        }

        let streak = ChallengeProgressCalculator.computeCurrentStreak(from: runs)
        #expect(streak == 5)
    }

    @Test("Current streak returns zero with no runs")
    func currentStreakNoRuns() {
        let streak = ChallengeProgressCalculator.computeCurrentStreak(from: [])
        #expect(streak == 0)
    }

    @Test("Current streak breaks on gap")
    func currentStreakGap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let runs = [
            makeRun(date: today),
            makeRun(date: calendar.date(byAdding: .day, value: -1, to: today)!),
            // gap: day -2 missing
            makeRun(date: calendar.date(byAdding: .day, value: -3, to: today)!),
        ]

        let streak = ChallengeProgressCalculator.computeCurrentStreak(from: runs)
        #expect(streak == 2)
    }

    // MARK: - Longest Streak

    @Test("Longest streak finds longest sequence")
    func longestStreak() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date.now.addingTimeInterval(-86400 * 30))
        let runs = [
            // 3-day streak
            makeRun(date: base),
            makeRun(date: calendar.date(byAdding: .day, value: 1, to: base)!),
            makeRun(date: calendar.date(byAdding: .day, value: 2, to: base)!),
            // gap
            // 5-day streak
            makeRun(date: calendar.date(byAdding: .day, value: 5, to: base)!),
            makeRun(date: calendar.date(byAdding: .day, value: 6, to: base)!),
            makeRun(date: calendar.date(byAdding: .day, value: 7, to: base)!),
            makeRun(date: calendar.date(byAdding: .day, value: 8, to: base)!),
            makeRun(date: calendar.date(byAdding: .day, value: 9, to: base)!),
        ]

        let longest = ChallengeProgressCalculator.computeLongestStreak(from: runs)
        #expect(longest == 5)
    }

    @Test("Empty runs give zero for both streaks")
    func emptyStreaks() {
        #expect(ChallengeProgressCalculator.computeCurrentStreak(from: []) == 0)
        #expect(ChallengeProgressCalculator.computeLongestStreak(from: []) == 0)
    }
}
