import Testing
import Foundation
@testable import UltraTrain

@Suite("ConvertRunToRouteUseCase Tests")
struct ConvertRunToRouteUseCaseTests {

    private func makeTrackPoints(count: Int) -> [TrackPoint] {
        (0..<count).map { i in
            TrackPoint(
                latitude: 45.0 + Double(i) * 0.001,
                longitude: 6.0 + Double(i) * 0.001,
                altitudeM: 1000 + Double(i) * 10,
                timestamp: Date(timeIntervalSince1970: Double(i) * 60),
                heartRate: nil
            )
        }
    }

    private func makeRun(trackPointCount: Int = 50) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            distanceKm: 10,
            elevationGainM: 500,
            elevationLossM: 300,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            gpsTrack: makeTrackPoints(count: trackPointCount),
            splits: [],
            pausedDuration: 0
        )
    }

    // MARK: - Success Cases

    @Test("Creates route from run with GPS data")
    func createsRouteFromRun() throws {
        let run = makeRun()
        let route = try ConvertRunToRouteUseCase.execute(from: run)

        #expect(route.source == .completedRun)
        #expect(route.sourceRunId == run.id)
        #expect(!route.trackPoints.isEmpty)
        #expect(!route.courseRoute.isEmpty)
        #expect(route.distanceKm > 0)
    }

    @Test("Custom name is used when provided")
    func customName() throws {
        let run = makeRun()
        let route = try ConvertRunToRouteUseCase.execute(from: run, name: "My Race Route")

        #expect(route.name == "My Race Route")
    }

    @Test("Default name includes date when no custom name")
    func defaultNameIncludesDate() throws {
        let run = makeRun()
        let route = try ConvertRunToRouteUseCase.execute(from: run)

        #expect(route.name.contains("Route from"))
    }

    @Test("Source run ID is set on result")
    func sourceRunIdSet() throws {
        let run = makeRun()
        let route = try ConvertRunToRouteUseCase.execute(from: run)

        #expect(route.sourceRunId == run.id)
    }

    // MARK: - Error Cases

    @Test("Throws when GPS track is empty")
    func throwsOnEmptyTrack() {
        let run = makeRun(trackPointCount: 0)

        #expect(throws: DomainError.self) {
            try ConvertRunToRouteUseCase.execute(from: run)
        }
    }

    @Test("Throws when GPS track has only one point")
    func throwsOnSinglePoint() {
        let run = makeRun(trackPointCount: 1)

        #expect(throws: DomainError.self) {
            try ConvertRunToRouteUseCase.execute(from: run)
        }
    }

    @Test("Succeeds with minimum two track points")
    func succeedsWithTwoPoints() throws {
        let run = makeRun(trackPointCount: 2)
        let route = try ConvertRunToRouteUseCase.execute(from: run)

        #expect(route.trackPoints.count == 2)
    }
}
