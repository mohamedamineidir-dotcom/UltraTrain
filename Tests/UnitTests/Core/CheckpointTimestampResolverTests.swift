import Foundation
import Testing
@testable import UltraTrain

@Suite("Checkpoint Timestamp Resolver Tests")
struct CheckpointTimestampResolverTests {

    private let startDate = Date(timeIntervalSince1970: 1_000_000)

    // Build a straight-line track along longitude (approx 111km per degree at equator)
    // Each point is ~1km apart at 10 min intervals
    private func makeTrack(pointCount: Int) -> [TrackPoint] {
        (0..<pointCount).map { i in
            TrackPoint(
                latitude: 0.0,
                longitude: Double(i) * 0.009, // ~1km spacing
                altitudeM: 100,
                timestamp: startDate.addingTimeInterval(Double(i) * 600),
                heartRate: nil
            )
        }
    }

    @Test("Timestamps interpolated correctly at checkpoint distances")
    func timestampsInterpolated() {
        let track = makeTrack(pointCount: 20) // ~19km track, 190min
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 5, elevationM: 100, hasAidStation: true),
            Checkpoint(id: UUID(), name: "CP2", distanceFromStartKm: 10, elevationM: 200, hasAidStation: false)
        ]

        let results = CheckpointLocationResolver.resolveTimestamps(
            checkpoints: checkpoints,
            along: track
        )

        #expect(results.count == 2)
        #expect(results[0].checkpoint.name == "CP1")
        #expect(results[1].checkpoint.name == "CP2")

        // CP1 at 5km should be ~50min from start (5 intervals * 10min)
        let cp1Elapsed = results[0].timestamp.timeIntervalSince(startDate)
        #expect(abs(cp1Elapsed - 3000) < 120) // within 2 min tolerance

        // CP2 at 10km should be ~100min from start
        let cp2Elapsed = results[1].timestamp.timeIntervalSince(startDate)
        #expect(abs(cp2Elapsed - 6000) < 120)
    }

    @Test("Empty track returns empty results")
    func emptyTrackReturnsEmpty() {
        let checkpoints = [
            Checkpoint(id: UUID(), name: "CP1", distanceFromStartKm: 5, elevationM: 100, hasAidStation: true)
        ]

        let results = CheckpointLocationResolver.resolveTimestamps(
            checkpoints: checkpoints,
            along: []
        )

        #expect(results.isEmpty)
    }

    @Test("Checkpoint beyond track uses last point timestamp")
    func checkpointBeyondTrack() {
        let track = makeTrack(pointCount: 5) // ~4km track
        let checkpoints = [
            Checkpoint(id: UUID(), name: "Far CP", distanceFromStartKm: 50, elevationM: 100, hasAidStation: false)
        ]

        let results = CheckpointLocationResolver.resolveTimestamps(
            checkpoints: checkpoints,
            along: track
        )

        #expect(results.count == 1)
        let lastTimestamp = track.last!.timestamp
        #expect(abs(results[0].timestamp.timeIntervalSince(lastTimestamp)) < 1)
    }
}
