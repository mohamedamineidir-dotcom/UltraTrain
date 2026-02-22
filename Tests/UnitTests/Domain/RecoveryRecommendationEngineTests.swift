import Testing
import Foundation
@testable import UltraTrain

@Suite("RecoveryRecommendationEngine Tests")
struct RecoveryRecommendationEngineTests {

    private func makeCheckIn(
        energy: Int = 3,
        soreness: Int = 1,
        mood: Int = 3,
        sleep: Int = 3
    ) -> MorningCheckIn {
        MorningCheckIn(
            id: UUID(),
            date: .now,
            perceivedEnergy: energy,
            muscleSoreness: soreness,
            mood: mood,
            sleepQualitySubjective: sleep,
            notes: nil
        )
    }

    @Test("High soreness recommends foam rolling")
    func highSoreness() {
        let checkIn = makeCheckIn(soreness: 4)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.contains { $0.title == "Foam Rolling & Stretching" })
    }

    @Test("Moderate soreness recommends light stretching")
    func moderateSoreness() {
        let checkIn = makeCheckIn(soreness: 3)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.contains { $0.title == "Light Stretching" })
    }

    @Test("Low energy recommends rest")
    func lowEnergy() {
        let checkIn = makeCheckIn(energy: 2)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.contains { $0.title == "Rest or Easy Recovery Run" })
    }

    @Test("Low mood recommends mental break")
    func lowMood() {
        let checkIn = makeCheckIn(mood: 2)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.contains { $0.title == "Mental Break" })
    }

    @Test("Poor sleep quality recommends prioritizing sleep")
    func poorSleep() {
        let checkIn = makeCheckIn(sleep: 1)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.contains { $0.title == "Prioritize Sleep Tonight" })
    }

    @Test("All good returns positive recommendation")
    func allGood() {
        let checkIn = makeCheckIn(energy: 5, soreness: 1, mood: 5, sleep: 5)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.contains { $0.title == "All Systems Go" })
    }

    @Test("No check-in and no recovery data returns all-clear")
    func noData() {
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: nil,
            recoveryScore: nil
        )
        #expect(result.count == 1)
        #expect(result.first?.title == "All Systems Go")
    }

    @Test("Results are sorted by priority descending")
    func sortedByPriority() {
        let checkIn = makeCheckIn(energy: 1, soreness: 5, mood: 1, sleep: 1)
        let result = RecoveryRecommendationEngine.recommend(
            readiness: nil,
            checkIn: checkIn,
            recoveryScore: nil
        )
        #expect(result.count > 1)
        for i in 0..<(result.count - 1) {
            #expect(result[i].priority >= result[i + 1].priority)
        }
    }
}
