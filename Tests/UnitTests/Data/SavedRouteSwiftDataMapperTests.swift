import Testing
import Foundation
@testable import UltraTrain

@Suite("SavedRouteSwiftDataMapper Tests")
struct SavedRouteSwiftDataMapperTests {

    // MARK: - Helpers

    private func makeTrackPoints(count: Int = 3) -> [TrackPoint] {
        (0..<count).map { (i: Int) -> TrackPoint in
            let lat = 45.0 + Double(i) * 0.01
            let lon = 6.0 + Double(i) * 0.01
            let alt = 1000.0 + Double(i) * 100.0
            let ts = Date(timeIntervalSince1970: Double(i) * 60)
            let hr: Int? = i % 2 == 0 ? 145 : nil
            return TrackPoint(
                latitude: lat,
                longitude: lon,
                altitudeM: alt,
                timestamp: ts,
                heartRate: hr
            )
        }
    }

    private func makeCheckpoints() -> [Checkpoint] {
        [
            Checkpoint(
                id: UUID(),
                name: "Les Contamines",
                distanceFromStartKm: 31,
                elevationM: 1200,
                hasAidStation: true
            ),
            Checkpoint(
                id: UUID(),
                name: "Col du Bonhomme",
                distanceFromStartKm: 50,
                elevationM: 2329,
                hasAidStation: false
            )
        ]
    }

    private func makeRoute(
        trackPoints: [TrackPoint]? = nil,
        courseRoute: [TrackPoint]? = nil,
        checkpoints: [Checkpoint]? = nil,
        source: RouteSource = .gpxImport,
        notes: String? = "Test notes",
        sourceRunId: UUID? = nil
    ) -> SavedRoute {
        SavedRoute(
            id: UUID(),
            name: "Test Route",
            distanceKm: 50,
            elevationGainM: 3000,
            elevationLossM: 2800,
            trackPoints: trackPoints ?? makeTrackPoints(),
            courseRoute: courseRoute ?? makeTrackPoints(count: 2),
            checkpoints: checkpoints ?? makeCheckpoints(),
            source: source,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            notes: notes,
            sourceRunId: sourceRunId
        )
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip preserves scalar fields")
    func roundTripScalarFields() {
        let route = makeRoute()
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored != nil)
        #expect(restored?.id == route.id)
        #expect(restored?.name == route.name)
        #expect(restored?.distanceKm == route.distanceKm)
        #expect(restored?.elevationGainM == route.elevationGainM)
        #expect(restored?.elevationLossM == route.elevationLossM)
        #expect(restored?.createdAt == route.createdAt)
        #expect(restored?.notes == route.notes)
    }

    @Test("Round-trip preserves source type")
    func roundTripSource() {
        for source in RouteSource.allCases {
            let route = makeRoute(source: source)
            let model = SavedRouteSwiftDataMapper.toSwiftData(route)
            let restored = SavedRouteSwiftDataMapper.toDomain(model)

            #expect(restored?.source == source)
        }
    }

    @Test("Round-trip preserves track points")
    func roundTripTrackPoints() {
        let points = makeTrackPoints(count: 5)
        let route = makeRoute(trackPoints: points)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.trackPoints.count == 5)
        #expect(restored?.trackPoints[0].latitude == points[0].latitude)
        #expect(restored?.trackPoints[0].longitude == points[0].longitude)
        #expect(restored?.trackPoints[0].altitudeM == points[0].altitudeM)
        #expect(restored?.trackPoints[0].heartRate == points[0].heartRate)
    }

    @Test("Round-trip preserves course route")
    func roundTripCourseRoute() {
        let coursePoints = makeTrackPoints(count: 4)
        let route = makeRoute(courseRoute: coursePoints)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.courseRoute.count == 4)
    }

    @Test("Round-trip preserves checkpoints")
    func roundTripCheckpoints() {
        let checkpoints = makeCheckpoints()
        let route = makeRoute(checkpoints: checkpoints)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.checkpoints.count == 2)
        #expect(restored?.checkpoints[0].name == "Les Contamines")
        #expect(restored?.checkpoints[0].distanceFromStartKm == 31)
        #expect(restored?.checkpoints[0].hasAidStation == true)
        #expect(restored?.checkpoints[1].name == "Col du Bonhomme")
        #expect(restored?.checkpoints[1].hasAidStation == false)
    }

    @Test("Round-trip preserves source run ID")
    func roundTripSourceRunId() {
        let runId = UUID()
        let route = makeRoute(sourceRunId: runId)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.sourceRunId == runId)
    }

    @Test("Nil source run ID preserved")
    func nilSourceRunId() {
        let route = makeRoute(sourceRunId: nil)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.sourceRunId == nil)
    }

    // MARK: - Edge Cases

    @Test("Empty track points round-trip correctly")
    func emptyTrackPoints() {
        let route = makeRoute(trackPoints: [], courseRoute: [])
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.trackPoints.isEmpty == true)
        #expect(restored?.courseRoute.isEmpty == true)
    }

    @Test("Empty checkpoints round-trip correctly")
    func emptyCheckpoints() {
        let route = makeRoute(checkpoints: [])
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.checkpoints.isEmpty == true)
    }

    @Test("Nil notes preserved")
    func nilNotes() {
        let route = makeRoute(notes: nil)
        let model = SavedRouteSwiftDataMapper.toSwiftData(route)
        let restored = SavedRouteSwiftDataMapper.toDomain(model)

        #expect(restored?.notes == nil)
    }

    // MARK: - Invalid Data

    @Test("Invalid source raw value returns nil")
    func invalidSourceReturnsNil() {
        let model = SavedRouteSwiftDataModel(
            id: UUID(),
            name: "Test",
            distanceKm: 10,
            elevationGainM: 500,
            elevationLossM: 500,
            sourceRaw: "invalid"
        )
        let result = SavedRouteSwiftDataMapper.toDomain(model)
        #expect(result == nil)
    }
}
