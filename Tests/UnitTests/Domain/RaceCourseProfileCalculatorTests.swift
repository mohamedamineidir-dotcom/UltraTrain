import Foundation
import Testing
@testable import UltraTrain

@Suite("RaceCourseProfileCalculator Tests")
struct RaceCourseProfileCalculatorTests {

    private func makeCheckpoint(
        name: String = "CP",
        distanceKm: Double,
        elevationM: Double,
        hasAidStation: Bool = false
    ) -> Checkpoint {
        Checkpoint(
            id: UUID(),
            name: name,
            distanceFromStartKm: distanceKm,
            elevationM: elevationM,
            hasAidStation: hasAidStation
        )
    }

    @Test("Empty checkpoints returns empty profile")
    func emptyCheckpoints() {
        let result = RaceCourseProfileCalculator.elevationProfile(from: [])
        #expect(result.isEmpty)
    }

    @Test("Profile matches checkpoint data")
    func profileMatchesCheckpoints() {
        let checkpoints = [
            makeCheckpoint(name: "Start", distanceKm: 0, elevationM: 1000),
            makeCheckpoint(name: "Summit", distanceKm: 15, elevationM: 2500),
            makeCheckpoint(name: "Finish", distanceKm: 30, elevationM: 1200),
        ]
        let result = RaceCourseProfileCalculator.elevationProfile(from: checkpoints)
        #expect(result.count == 3)
        #expect(result[0].distanceKm == 0)
        #expect(result[0].altitudeM == 1000)
        #expect(result[1].distanceKm == 15)
        #expect(result[1].altitudeM == 2500)
    }

    @Test("Profile is sorted by distance regardless of input order")
    func profileSortedByDistance() {
        let checkpoints = [
            makeCheckpoint(distanceKm: 20, elevationM: 800),
            makeCheckpoint(distanceKm: 5, elevationM: 1500),
            makeCheckpoint(distanceKm: 10, elevationM: 2000),
        ]
        let result = RaceCourseProfileCalculator.elevationProfile(from: checkpoints)
        #expect(result[0].distanceKm == 5)
        #expect(result[1].distanceKm == 10)
        #expect(result[2].distanceKm == 20)
    }

    @Test("Elevation changes calculates gain and loss")
    func elevationChanges() {
        let checkpoints = [
            makeCheckpoint(distanceKm: 0, elevationM: 1000),
            makeCheckpoint(distanceKm: 10, elevationM: 2000),
            makeCheckpoint(distanceKm: 20, elevationM: 1500),
        ]
        let (gain, loss) = RaceCourseProfileCalculator.elevationChanges(from: checkpoints)
        #expect(gain == 1000)
        #expect(loss == 500)
    }
}
