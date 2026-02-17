import Foundation
import Testing
@testable import UltraTrain

@Suite("CheckpointLocationResolver Tests")
struct CheckpointLocationResolverTests {

    // MARK: - Helpers

    private func makeCheckpoint(
        name: String = "CP",
        distanceKm: Double,
        hasAidStation: Bool = false
    ) -> Checkpoint {
        Checkpoint(
            id: UUID(),
            name: name,
            distanceFromStartKm: distanceKm,
            elevationM: 500,
            hasAidStation: hasAidStation
        )
    }

    /// Creates track points along a straight north-south line.
    /// Each point is ~111m apart (0.001 degrees latitude ≈ 111m).
    private func makeStraightTrack(count: Int) -> [TrackPoint] {
        let baseDate = Date.now
        return (0..<count).map { i in
            TrackPoint(
                latitude: 45.0 + Double(i) * 0.001,
                longitude: 6.0,
                altitudeM: 500,
                timestamp: baseDate.addingTimeInterval(Double(i) * 10),
                heartRate: nil
            )
        }
    }

    // MARK: - Empty Inputs

    @Test("Empty checkpoints returns empty result")
    func emptyCheckpoints() {
        let track = makeStraightTrack(count: 10)
        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [],
            along: track
        )
        #expect(result.isEmpty)
    }

    @Test("Empty track returns empty result")
    func emptyTrack() {
        let cp = makeCheckpoint(distanceKm: 1.0)
        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [cp],
            along: []
        )
        #expect(result.isEmpty)
    }

    @Test("Single-point track returns empty result")
    func singlePointTrack() {
        let cp = makeCheckpoint(distanceKm: 0.5)
        let track = makeStraightTrack(count: 1)
        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [cp],
            along: track
        )
        #expect(result.isEmpty)
    }

    // MARK: - Resolution

    @Test("Checkpoint at known distance is interpolated correctly")
    func singleCheckpointInterpolation() {
        // 20 points, each ~111m apart ≈ 2.1km total track
        let track = makeStraightTrack(count: 20)
        let cp = makeCheckpoint(name: "Aid1", distanceKm: 1.0, hasAidStation: true)

        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [cp],
            along: track
        )

        #expect(result.count == 1)
        #expect(result[0].checkpoint.name == "Aid1")
        #expect(result[0].checkpoint.hasAidStation == true)
        // 1km = 1000m. Each segment ~111m. Checkpoint should be between point 8 and 9
        // lat should be roughly 45.0 + 9 * 0.001 = 45.009
        #expect(result[0].coordinate.latitude > 45.008)
        #expect(result[0].coordinate.latitude < 45.010)
        #expect(abs(result[0].coordinate.longitude - 6.0) < 0.001)
    }

    @Test("Checkpoint beyond track distance falls back to last point")
    func checkpointBeyondTrack() {
        let track = makeStraightTrack(count: 5) // ~0.44km total
        let cp = makeCheckpoint(distanceKm: 10.0)

        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [cp],
            along: track
        )

        #expect(result.count == 1)
        let lastPoint = track.last!
        #expect(abs(result[0].coordinate.latitude - lastPoint.latitude) < 0.0001)
        #expect(abs(result[0].coordinate.longitude - lastPoint.longitude) < 0.0001)
    }

    @Test("Multiple checkpoints are all resolved in order")
    func multipleCheckpoints() {
        let track = makeStraightTrack(count: 30) // ~3.2km total
        let cp1 = makeCheckpoint(name: "CP1", distanceKm: 0.5)
        let cp2 = makeCheckpoint(name: "CP2", distanceKm: 1.5, hasAidStation: true)
        let cp3 = makeCheckpoint(name: "CP3", distanceKm: 2.5)

        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [cp3, cp1, cp2], // deliberately unordered
            along: track
        )

        #expect(result.count == 3)
        // Should be sorted by distance
        #expect(result[0].checkpoint.name == "CP1")
        #expect(result[1].checkpoint.name == "CP2")
        #expect(result[2].checkpoint.name == "CP3")
        // Each should have progressively higher latitude
        #expect(result[0].coordinate.latitude < result[1].coordinate.latitude)
        #expect(result[1].coordinate.latitude < result[2].coordinate.latitude)
    }

    @Test("Checkpoint at zero distance resolves near start")
    func checkpointAtZeroDistance() {
        let track = makeStraightTrack(count: 10)
        let cp = makeCheckpoint(distanceKm: 0.0)

        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [cp],
            along: track
        )

        #expect(result.count == 1)
        // Should be very close to the first track point
        #expect(abs(result[0].coordinate.latitude - 45.0) < 0.001)
    }

    @Test("Aid station flag is preserved through resolution")
    func aidStationFlagPreserved() {
        let track = makeStraightTrack(count: 20)
        let aidStation = makeCheckpoint(name: "Water", distanceKm: 1.0, hasAidStation: true)
        let regular = makeCheckpoint(name: "Gate", distanceKm: 0.5, hasAidStation: false)

        let result = CheckpointLocationResolver.resolveLocations(
            checkpoints: [aidStation, regular],
            along: track
        )

        #expect(result.count == 2)
        let aid = result.first { $0.checkpoint.name == "Water" }
        let gate = result.first { $0.checkpoint.name == "Gate" }
        #expect(aid?.checkpoint.hasAidStation == true)
        #expect(gate?.checkpoint.hasAidStation == false)
    }
}
