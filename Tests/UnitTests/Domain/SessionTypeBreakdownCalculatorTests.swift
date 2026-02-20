import Foundation
import Testing
@testable import UltraTrain

@Suite("Session Type Breakdown Calculator Tests")
struct SessionTypeBreakdownCalculatorTests {

    // MARK: - Helpers

    private func makeSession(type: SessionType, distanceKm: Double = 10, duration: TimeInterval = 3600) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: Date.now,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: 200,
            plannedDuration: duration,
            intensity: .moderate,
            description: "\(type.rawValue) session",
            isCompleted: false,
            isSkipped: false
        )
    }

    private func makePlan(sessions: [TrainingSession]) -> TrainingPlan {
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: Date.now,
            endDate: Date.now.adding(days: 6),
            phase: .build,
            sessions: sessions,
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1000
        )
        return TrainingPlan(
            id: UUID(),
            athleteId: UUID(),
            targetRaceId: UUID(),
            createdAt: Date.now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )
    }

    // MARK: - Tests

    @Test("Empty plan produces empty stats")
    func emptyPlan() {
        let plan = makePlan(sessions: [])
        let stats = SessionTypeBreakdownCalculator.compute(from: plan)
        #expect(stats.isEmpty)
    }

    @Test("Rest sessions are excluded")
    func restExcluded() {
        let plan = makePlan(sessions: [
            makeSession(type: .rest),
            makeSession(type: .longRun),
        ])

        let stats = SessionTypeBreakdownCalculator.compute(from: plan)
        #expect(stats.count == 1)
        #expect(stats[0].sessionType == .longRun)
        #expect(stats[0].percentage == 100)
    }

    @Test("Mixed types produce correct percentages")
    func mixedTypes() {
        let plan = makePlan(sessions: [
            makeSession(type: .longRun),
            makeSession(type: .longRun),
            makeSession(type: .tempo),
            makeSession(type: .intervals),
            makeSession(type: .recovery),
        ])

        let stats = SessionTypeBreakdownCalculator.compute(from: plan)
        #expect(stats.count == 4)

        let longRunStats = stats.first { $0.sessionType == .longRun }
        #expect(longRunStats != nil)
        #expect(longRunStats!.count == 2)
        #expect(longRunStats!.percentage == 40)

        let totalPercent = stats.reduce(0.0) { $0 + $1.percentage }
        #expect(abs(totalPercent - 100) < 0.01)
    }

    @Test("All same type produces 100%")
    func allSameType() {
        let plan = makePlan(sessions: [
            makeSession(type: .tempo),
            makeSession(type: .tempo),
            makeSession(type: .tempo),
        ])

        let stats = SessionTypeBreakdownCalculator.compute(from: plan)
        #expect(stats.count == 1)
        #expect(stats[0].sessionType == .tempo)
        #expect(stats[0].percentage == 100)
        #expect(stats[0].count == 3)
    }

    @Test("Stats sorted by percentage descending")
    func sortedByPercentage() {
        let plan = makePlan(sessions: [
            makeSession(type: .longRun),
            makeSession(type: .longRun),
            makeSession(type: .longRun),
            makeSession(type: .tempo),
            makeSession(type: .intervals),
        ])

        let stats = SessionTypeBreakdownCalculator.compute(from: plan)
        #expect(stats[0].sessionType == .longRun)
        for i in 1..<stats.count {
            #expect(stats[i - 1].percentage >= stats[i].percentage)
        }
    }

    @Test("Distance and duration aggregated correctly")
    func aggregation() {
        let plan = makePlan(sessions: [
            makeSession(type: .longRun, distanceKm: 20, duration: 7200),
            makeSession(type: .longRun, distanceKm: 25, duration: 9000),
        ])

        let stats = SessionTypeBreakdownCalculator.compute(from: plan)
        #expect(stats[0].totalDistanceKm == 45)
        #expect(stats[0].totalDuration == 16200)
    }
}
