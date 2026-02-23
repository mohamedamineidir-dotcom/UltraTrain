import Foundation
import Testing
@testable import UltraTrain

@Suite("AthleteMapper Tests")
struct AthleteMapperTests {

    @Test("toDomain maps valid DTO to Athlete")
    func toDomainMapsValidDTO() {
        let dto = AthleteDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            firstName: "Kilian",
            lastName: "Jornet",
            dateOfBirth: "1987-10-27T00:00:00Z",
            weightKg: 60.0,
            heightCm: 171.0,
            restingHeartRate: 40,
            maxHeartRate: 195,
            experienceLevel: "elite",
            weeklyVolumeKm: 120.0,
            longestRunKm: 170.0
        )

        let athlete = AthleteMapper.toDomain(dto)

        #expect(athlete != nil)
        #expect(athlete?.firstName == "Kilian")
        #expect(athlete?.lastName == "Jornet")
        #expect(athlete?.experienceLevel == .elite)
        #expect(athlete?.weightKg == 60.0)
        #expect(athlete?.restingHeartRate == 40)
        #expect(athlete?.weeklyVolumeKm == 120.0)
    }

    @Test("toDomain returns nil for invalid UUID")
    func toDomainReturnsNilForInvalidId() {
        let dto = AthleteDTO(
            id: "not-valid",
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: "1990-01-01T00:00:00Z",
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: "intermediate",
            weeklyVolumeKm: 50,
            longestRunKm: 30
        )

        #expect(AthleteMapper.toDomain(dto) == nil)
    }

    @Test("toDomain returns nil for invalid experience level")
    func toDomainReturnsNilForInvalidLevel() {
        let dto = AthleteDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: "1990-01-01T00:00:00Z",
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: "legendary",
            weeklyVolumeKm: 50,
            longestRunKm: 30
        )

        #expect(AthleteMapper.toDomain(dto) == nil)
    }

    @Test("Round-trip preserves athlete data")
    func roundTripPreservesData() {
        let original = Athlete(
            id: UUID(),
            firstName: "Jim",
            lastName: "Walmsley",
            dateOfBirth: Date(timeIntervalSince1970: 631152000),
            weightKg: 68.0,
            heightCm: 180.0,
            restingHeartRate: 45,
            maxHeartRate: 190,
            experienceLevel: .advanced,
            weeklyVolumeKm: 160.0,
            longestRunKm: 161.0,
            preferredUnit: .metric
        )

        let dto = AthleteMapper.toDTO(original)
        let restored = AthleteMapper.toDomain(dto)

        #expect(restored != nil)
        #expect(restored?.id == original.id)
        #expect(restored?.firstName == original.firstName)
        #expect(restored?.lastName == original.lastName)
        #expect(restored?.experienceLevel == original.experienceLevel)
        #expect(restored?.weightKg == original.weightKg)
        #expect(restored?.weeklyVolumeKm == original.weeklyVolumeKm)
    }
}
