import Foundation
import Testing
@testable import UltraTrain

@Suite("RunMapper Remote Tests")
struct RunMapperRemoteTests {

    // MARK: - toDomain

    @Test("toDomain maps valid response to CompletedRun")
    func toDomainMapsValidResponse() {
        let dto = RunResponseDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            date: "2026-02-20T08:30:00Z",
            distanceKm: 15.5,
            elevationGainM: 450.0,
            elevationLossM: 420.0,
            duration: 5400,
            averageHeartRate: 145,
            maxHeartRate: 172,
            averagePaceSecondsPerKm: 348.4,
            gpsTrack: [
                TrackPointDTO(latitude: 45.5, longitude: 6.1, altitudeM: 1200, timestamp: "2026-02-20T08:30:00Z", heartRate: 140),
                TrackPointDTO(latitude: 45.51, longitude: 6.11, altitudeM: 1250, timestamp: "2026-02-20T08:35:00Z", heartRate: 150)
            ],
            splits: [
                SplitDTO(id: "A0000000-0000-0000-0000-000000000001", kilometerNumber: 1, duration: 340, elevationChangeM: 30, averageHeartRate: 142)
            ],
            notes: "Great trail run",
            createdAt: "2026-02-20T09:00:00Z"
        )

        let athleteId = UUID()
        let run = RunMapper.toDomain(dto, athleteId: athleteId)

        #expect(run != nil)
        #expect(run?.id.uuidString == "550E8400-E29B-41D4-A716-446655440000")
        #expect(run?.athleteId == athleteId)
        #expect(run?.distanceKm == 15.5)
        #expect(run?.elevationGainM == 450.0)
        #expect(run?.elevationLossM == 420.0)
        #expect(run?.duration == 5400)
        #expect(run?.averageHeartRate == 145)
        #expect(run?.maxHeartRate == 172)
        #expect(run?.averagePaceSecondsPerKm == 348.4)
        #expect(run?.gpsTrack.count == 2)
        #expect(run?.splits.count == 1)
        #expect(run?.notes == "Great trail run")
    }

    @Test("toDomain returns nil for invalid UUID")
    func toDomainReturnsNilForInvalidId() {
        let dto = RunResponseDTO(
            id: "not-a-uuid",
            date: "2026-02-20T08:30:00Z",
            distanceKm: 10,
            elevationGainM: 100,
            elevationLossM: 90,
            duration: 3600,
            averageHeartRate: nil,
            maxHeartRate: nil,
            averagePaceSecondsPerKm: 360,
            gpsTrack: nil,
            splits: nil,
            notes: nil,
            createdAt: nil
        )

        let run = RunMapper.toDomain(dto, athleteId: UUID())
        #expect(run == nil)
    }

    @Test("toDomain returns nil for invalid date")
    func toDomainReturnsNilForInvalidDate() {
        let dto = RunResponseDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            date: "not-a-date",
            distanceKm: 10,
            elevationGainM: 100,
            elevationLossM: 90,
            duration: 3600,
            averageHeartRate: nil,
            maxHeartRate: nil,
            averagePaceSecondsPerKm: 360,
            gpsTrack: nil,
            splits: nil,
            notes: nil,
            createdAt: nil
        )

        let run = RunMapper.toDomain(dto, athleteId: UUID())
        #expect(run == nil)
    }

    @Test("toDomain handles nil GPS track and splits gracefully")
    func toDomainHandlesNilArrays() {
        let dto = RunResponseDTO(
            id: "550e8400-e29b-41d4-a716-446655440000",
            date: "2026-02-20T08:30:00Z",
            distanceKm: 10,
            elevationGainM: 100,
            elevationLossM: 90,
            duration: 3600,
            averageHeartRate: nil,
            maxHeartRate: nil,
            averagePaceSecondsPerKm: 360,
            gpsTrack: nil,
            splits: nil,
            notes: nil,
            createdAt: nil
        )

        let run = RunMapper.toDomain(dto, athleteId: UUID())
        #expect(run != nil)
        #expect(run?.gpsTrack.isEmpty == true)
        #expect(run?.splits.isEmpty == true)
    }

    // MARK: - toUploadDTO

    @Test("toUploadDTO maps CompletedRun to upload DTO")
    func toUploadDTOMaps() {
        let run = makeRun()
        let dto = RunMapper.toUploadDTO(run)

        #expect(dto.id == run.id.uuidString)
        #expect(dto.distanceKm == 12.0)
        #expect(dto.elevationGainM == 300.0)
        #expect(dto.duration == 4200)
        #expect(dto.idempotencyKey == run.id.uuidString)
    }

    // MARK: - Helpers

    private func makeRun() -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date(),
            distanceKm: 12.0,
            elevationGainM: 300.0,
            elevationLossM: 280.0,
            duration: 4200,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 350,
            gpsTrack: [],
            splits: [],
            notes: nil,
            pausedDuration: 0
        )
    }
}
