import Testing
import Foundation
@testable import UltraTrain

@Suite("AchievementEvaluator Tests")
struct AchievementEvaluatorTests {

    private func makeRun(distanceKm: Double = 10, elevationGainM: Double = 0, date: Date = .now) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 0,
            duration: distanceKm * 360,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    @Test("Evaluates total distance achievements")
    func totalDistance() {
        let runs = (0..<20).map { _ in makeRun(distanceKm: 6) } // 120km total
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("total_100km"))
        #expect(!ids.contains("total_500km"))
    }

    @Test("Evaluates single run distance achievement")
    func singleRunDistance() {
        let runs = [makeRun(distanceKm: 55)]
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("single_50k"))
    }

    @Test("Evaluates total elevation achievement")
    func totalElevation() {
        let runs = (0..<60).map { _ in makeRun(elevationGainM: 100) } // 6000m total
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("total_5000m_elev"))
        #expect(!ids.contains("total_10000m_elev"))
    }

    @Test("Evaluates total runs achievement")
    func totalRuns() {
        let runs = (0..<12).map { _ in makeRun() }
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("total_10_runs"))
    }

    @Test("Evaluates streak achievement")
    func streak() {
        let calendar = Calendar.current
        let runs = (0..<8).map { i in
            makeRun(date: calendar.date(byAdding: .day, value: -i, to: .now)!)
        }
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("streak_7"))
    }

    @Test("Does not unlock already unlocked achievements")
    func alreadyUnlocked() {
        let runs = (0..<20).map { _ in makeRun(distanceKm: 6) } // 120km
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set(["total_100km"])
        )
        let ids = result.map(\.achievementId)
        #expect(!ids.contains("total_100km"))
    }

    @Test("Evaluates personal record achievement")
    func personalRecord() {
        let records = [
            PersonalRecord(
                id: UUID(),
                type: .fastestPace,
                value: 240,
                date: .now,
                runId: UUID()
            )
        ]
        let result = AchievementEvaluator.evaluate(
            runs: [],
            enrollments: [],
            races: [],
            personalRecords: records,
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("first_pr"))
    }

    @Test("Single 10K run unlocks single_10km achievement")
    func single10k() {
        let runs = [makeRun(distanceKm: 10)]
        let result = AchievementEvaluator.evaluate(
            runs: runs,
            enrollments: [],
            races: [],
            personalRecords: [],
            alreadyUnlocked: Set()
        )
        let ids = result.map(\.achievementId)
        #expect(ids.contains("single_10km"))
    }
}
