import Testing
import Foundation
@testable import UltraTrain

@Suite("AthleteSwiftDataMapper Tests")
struct AthleteSwiftDataMapperTests {

    private func makeAthlete(
        id: UUID = UUID(),
        philosophy: TrainingPhilosophy = .balanced,
        preferredRunsPerWeek: Int = 5,
        personalBests: [PersonalBest] = [],
        customZones: [Int]? = nil
    ) -> Athlete {
        Athlete(
            id: id,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Date(timeIntervalSince1970: 700_000_000),
            weightKg: 72,
            heightCm: 178,
            restingHeartRate: 52,
            maxHeartRate: 190,
            experienceLevel: .advanced,
            weeklyVolumeKm: 60,
            longestRunKm: 42,
            preferredUnit: .metric,
            customZoneThresholds: customZones,
            personalBests: personalBests,
            trainingPhilosophy: philosophy,
            preferredRunsPerWeek: preferredRunsPerWeek
        )
    }

    @Test("Round-trip preserves all basic athlete fields")
    func roundTripBasicFields() {
        let athlete = makeAthlete()
        let model = AthleteSwiftDataMapper.toSwiftData(athlete)
        let restored = AthleteSwiftDataMapper.toDomain(model)

        #expect(restored != nil)
        #expect(restored?.id == athlete.id)
        #expect(restored?.firstName == "Test")
        #expect(restored?.lastName == "Runner")
        #expect(restored?.weightKg == 72)
        #expect(restored?.heightCm == 178)
        #expect(restored?.restingHeartRate == 52)
        #expect(restored?.maxHeartRate == 190)
        #expect(restored?.experienceLevel == .advanced)
        #expect(restored?.weeklyVolumeKm == 60)
        #expect(restored?.longestRunKm == 42)
        #expect(restored?.preferredUnit == .metric)
    }

    @Test("Round-trip preserves training philosophy")
    func roundTripPhilosophy() {
        for philosophy in TrainingPhilosophy.allCases {
            let athlete = makeAthlete(philosophy: philosophy)
            let model = AthleteSwiftDataMapper.toSwiftData(athlete)
            let restored = AthleteSwiftDataMapper.toDomain(model)
            #expect(restored?.trainingPhilosophy == philosophy)
        }
    }

    @Test("Round-trip preserves preferred runs per week")
    func roundTripPreferredRunsPerWeek() {
        let athlete = makeAthlete(preferredRunsPerWeek: 5)
        let model = AthleteSwiftDataMapper.toSwiftData(athlete)
        let restored = AthleteSwiftDataMapper.toDomain(model)
        #expect(restored?.preferredRunsPerWeek == 5)
    }

    @Test("Nil preferred runs in SwiftData defaults to 5")
    func nilPreferredRunsDefaultsTo5() {
        // Simulate a legacy SwiftData model where preferredRunsPerWeek was nil
        let model = AthleteSwiftDataModel(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Date(timeIntervalSince1970: 700_000_000),
            weightKg: 72,
            heightCm: 178,
            restingHeartRate: 52,
            maxHeartRate: 190,
            experienceLevelRaw: "advanced",
            weeklyVolumeKm: 60,
            longestRunKm: 42,
            preferredUnitRaw: "metric",
            preferredRunsPerWeek: nil
        )
        let restored = AthleteSwiftDataMapper.toDomain(model)
        #expect(restored?.preferredRunsPerWeek == 5)
    }

    @Test("Round-trip preserves personal bests")
    func roundTripPersonalBests() {
        let pbs = [
            PersonalBest(id: UUID(), distance: .marathon, timeSeconds: 12600, date: .now),
            PersonalBest(id: UUID(), distance: .tenK, timeSeconds: 2400, date: .now)
        ]
        let athlete = makeAthlete(personalBests: pbs)
        let model = AthleteSwiftDataMapper.toSwiftData(athlete)
        let restored = AthleteSwiftDataMapper.toDomain(model)
        #expect(restored?.personalBests.count == 2)
    }

    @Test("Round-trip preserves custom zone thresholds")
    func roundTripCustomZones() {
        let zones = [130, 150, 165, 180]
        let athlete = makeAthlete(customZones: zones)
        let model = AthleteSwiftDataMapper.toSwiftData(athlete)
        let restored = AthleteSwiftDataMapper.toDomain(model)
        #expect(restored?.customZoneThresholds == zones)
    }

    @Test("Invalid experience level raw value returns nil")
    func invalidExperienceReturnsNil() {
        let model = AthleteSwiftDataModel(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: .now,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevelRaw: "invalid",
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnitRaw: "metric"
        )
        let result = AthleteSwiftDataMapper.toDomain(model)
        #expect(result == nil)
    }

    @Test("Unknown philosophy raw value defaults to balanced")
    func unknownPhilosophyDefaultsToBalanced() {
        let model = AthleteSwiftDataModel(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: .now,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevelRaw: "intermediate",
            weeklyVolumeKm: 40,
            longestRunKm: 25,
            preferredUnitRaw: "metric",
            trainingPhilosophyRaw: "unknown_value"
        )
        let result = AthleteSwiftDataMapper.toDomain(model)
        #expect(result?.trainingPhilosophy == .balanced)
    }
}
