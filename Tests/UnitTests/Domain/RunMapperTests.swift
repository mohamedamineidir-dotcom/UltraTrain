import Foundation
import Testing
@testable import UltraTrain

@Suite("RunMapper Tests")
struct RunMapperTests {

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let fixedId = UUID()
    private let athleteId = UUID()
    private let splitId = UUID()

    private func makeRun(
        notes: String? = nil,
        trackPoints: [TrackPoint] = [],
        splits: [Split] = []
    ) -> CompletedRun {
        CompletedRun(
            id: fixedId,
            athleteId: athleteId,
            date: fixedDate,
            distanceKm: 25.5,
            elevationGainM: 1500,
            elevationLossM: 1400,
            duration: 10800,
            averageHeartRate: 145,
            maxHeartRate: 178,
            averagePaceSecondsPerKm: 423.5,
            gpsTrack: trackPoints,
            splits: splits,
            notes: notes,
            pausedDuration: 120
        )
    }

    // MARK: - Basic Field Mapping

    @Test("toUploadDTO maps basic fields correctly")
    func mapsBasicFields() {
        let run = makeRun()
        let dto = RunMapper.toUploadDTO(run)

        #expect(dto.id == fixedId.uuidString)
        #expect(dto.distanceKm == 25.5)
        #expect(dto.elevationGainM == 1500)
        #expect(dto.elevationLossM == 1400)
        #expect(dto.duration == 10800)
        #expect(dto.averageHeartRate == 145)
        #expect(dto.maxHeartRate == 178)
        #expect(dto.averagePaceSecondsPerKm == 423.5)
    }

    @Test("toUploadDTO maps date as ISO8601 string")
    func mapsDateAsISO8601() {
        let run = makeRun()
        let dto = RunMapper.toUploadDTO(run)

        let formatter = ISO8601DateFormatter()
        let expectedDate = formatter.string(from: fixedDate)
        #expect(dto.date == expectedDate)
    }

    // MARK: - Track Points

    @Test("TrackPoints are mapped with correct lat/lon/alt")
    func mapsTrackPoints() {
        let trackPoints = [
            TrackPoint(
                latitude: 45.832,
                longitude: 6.865,
                altitudeM: 1000,
                timestamp: fixedDate,
                heartRate: 140
            ),
            TrackPoint(
                latitude: 45.840,
                longitude: 6.870,
                altitudeM: 1200,
                timestamp: fixedDate.addingTimeInterval(300),
                heartRate: 155
            )
        ]
        let run = makeRun(trackPoints: trackPoints)
        let dto = RunMapper.toUploadDTO(run)

        #expect(dto.gpsTrack.count == 2)
        #expect(dto.gpsTrack[0].latitude == 45.832)
        #expect(dto.gpsTrack[0].longitude == 6.865)
        #expect(dto.gpsTrack[0].altitudeM == 1000)
        #expect(dto.gpsTrack[0].heartRate == 140)
        #expect(dto.gpsTrack[1].latitude == 45.840)
        #expect(dto.gpsTrack[1].longitude == 6.870)
        #expect(dto.gpsTrack[1].altitudeM == 1200)
        #expect(dto.gpsTrack[1].heartRate == 155)
    }

    // MARK: - Splits

    @Test("Splits are mapped correctly")
    func mapsSplits() {
        let splits = [
            Split(
                id: splitId,
                kilometerNumber: 1,
                duration: 360,
                elevationChangeM: 50,
                averageHeartRate: 138
            ),
            Split(
                id: UUID(),
                kilometerNumber: 2,
                duration: 380,
                elevationChangeM: -20,
                averageHeartRate: 142
            )
        ]
        let run = makeRun(splits: splits)
        let dto = RunMapper.toUploadDTO(run)

        #expect(dto.splits.count == 2)
        #expect(dto.splits[0].id == splitId.uuidString)
        #expect(dto.splits[0].kilometerNumber == 1)
        #expect(dto.splits[0].duration == 360)
        #expect(dto.splits[0].elevationChangeM == 50)
        #expect(dto.splits[0].averageHeartRate == 138)
        #expect(dto.splits[1].kilometerNumber == 2)
        #expect(dto.splits[1].duration == 380)
        #expect(dto.splits[1].elevationChangeM == -20)
        #expect(dto.splits[1].averageHeartRate == 142)
    }

    // MARK: - Notes

    @Test("Notes are included when present")
    func mapsNotesWhenPresent() {
        let run = makeRun(notes: "Great trail run in the Alps!")
        let dto = RunMapper.toUploadDTO(run)
        #expect(dto.notes == "Great trail run in the Alps!")
    }

    @Test("Notes are nil when not provided")
    func notesNilWhenAbsent() {
        let run = makeRun(notes: nil)
        let dto = RunMapper.toUploadDTO(run)
        #expect(dto.notes == nil)
    }

    // MARK: - Idempotency Key

    @Test("Run id is used as idempotency key")
    func idempotencyKeyMatchesRunId() {
        let run = makeRun()
        let dto = RunMapper.toUploadDTO(run)
        #expect(dto.idempotencyKey == fixedId.uuidString)
        #expect(dto.idempotencyKey == dto.id)
    }
}
