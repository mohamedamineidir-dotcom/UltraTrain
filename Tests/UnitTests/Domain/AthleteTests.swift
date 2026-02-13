import Foundation
import Testing
@testable import UltraTrain

@Suite("Athlete Model Tests")
struct AthleteTests {

    @Test("Effective distance includes elevation gain")
    func effectiveDistanceCalculation() {
        let race = Race(
            id: UUID(),
            name: "UTMB",
            date: .now,
            distanceKm: 171,
            elevationGainM: 10000,
            elevationLossM: 10000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .technical
        )
        #expect(race.effectiveDistanceKm == 271.0)
    }

    @Test("Age calculation from date of birth")
    func ageCalculation() {
        let calendar = Calendar.current
        let thirtyYearsAgo = calendar.date(byAdding: .year, value: -30, to: .now)!
        let athlete = Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: thirtyYearsAgo,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 190,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 42,
            preferredUnit: .metric
        )
        #expect(athlete.age == 30)
    }
}
