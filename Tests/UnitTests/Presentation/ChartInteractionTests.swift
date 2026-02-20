import Foundation
import Testing
@testable import UltraTrain

@Suite("Chart Interaction Helper Tests")
struct ChartInteractionTests {

    // MARK: - ElevationProfileChart Nearest Point

    @Test("Nearest elevation point returns closest by distance")
    func nearestElevationPoint() {
        let points = [
            ElevationProfilePoint(distanceKm: 0, altitudeM: 500),
            ElevationProfilePoint(distanceKm: 1, altitudeM: 600),
            ElevationProfilePoint(distanceKm: 2, altitudeM: 700),
            ElevationProfilePoint(distanceKm: 3, altitudeM: 650)
        ]

        let nearest = points.min(by: {
            abs($0.distanceKm - 1.3) < abs($1.distanceKm - 1.3)
        })

        #expect(nearest?.distanceKm == 1)
        #expect(nearest?.altitudeM == 600)
    }

    @Test("Nearest elevation point with empty array returns nil")
    func nearestElevationPointEmpty() {
        let points: [ElevationProfilePoint] = []

        let nearest = points.min(by: {
            abs($0.distanceKm - 1.0) < abs($1.distanceKm - 1.0)
        })

        #expect(nearest == nil)
    }

    @Test("Nearest elevation point at exact distance returns that point")
    func nearestElevationPointExact() {
        let points = [
            ElevationProfilePoint(distanceKm: 0, altitudeM: 500),
            ElevationProfilePoint(distanceKm: 2, altitudeM: 700),
            ElevationProfilePoint(distanceKm: 4, altitudeM: 900)
        ]

        let nearest = points.min(by: {
            abs($0.distanceKm - 2.0) < abs($1.distanceKm - 2.0)
        })

        #expect(nearest?.distanceKm == 2)
        #expect(nearest?.altitudeM == 700)
    }

    // MARK: - ElevationPaceChart Nearest Points

    @Test("Nearest overlay elevation point found correctly")
    func nearestOverlayElevation() {
        let overlay = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: [
                ElevationProfilePoint(distanceKm: 0, altitudeM: 500),
                ElevationProfilePoint(distanceKm: 1, altitudeM: 600),
                ElevationProfilePoint(distanceKm: 2, altitudeM: 700)
            ],
            splits: [
                Split(id: UUID(), kilometerNumber: 1, duration: 360, elevationChangeM: 100, averageHeartRate: 150),
                Split(id: UUID(), kilometerNumber: 2, duration: 400, elevationChangeM: 100, averageHeartRate: 155)
            ]
        )

        let nearestElev = overlay.elevation.min(by: {
            abs($0.distanceKm - 0.8) < abs($1.distanceKm - 0.8)
        })

        #expect(nearestElev != nil)
        #expect(nearestElev!.altitudeM >= 500)
    }

    @Test("Nearest overlay pace point found correctly")
    func nearestOverlayPace() {
        let overlay = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: [
                ElevationProfilePoint(distanceKm: 0, altitudeM: 500),
                ElevationProfilePoint(distanceKm: 1, altitudeM: 600),
                ElevationProfilePoint(distanceKm: 2, altitudeM: 700)
            ],
            splits: [
                Split(id: UUID(), kilometerNumber: 1, duration: 360, elevationChangeM: 100, averageHeartRate: 150),
                Split(id: UUID(), kilometerNumber: 2, duration: 400, elevationChangeM: 100, averageHeartRate: 155)
            ]
        )

        let nearestPace = overlay.pace.min(by: {
            abs($0.distanceKm - 1.5) < abs($1.distanceKm - 1.5)
        })

        #expect(nearestPace != nil)
        #expect(nearestPace!.paceSecondsPerKm > 0)
    }

    // MARK: - PaceSplitsChart Split Lookup

    @Test("Find split by km number returns correct split")
    func findSplitByKm() {
        let splits = [
            Split(id: UUID(), kilometerNumber: 1, duration: 360, elevationChangeM: 50, averageHeartRate: 145),
            Split(id: UUID(), kilometerNumber: 2, duration: 380, elevationChangeM: -30, averageHeartRate: 150),
            Split(id: UUID(), kilometerNumber: 3, duration: 340, elevationChangeM: 20, averageHeartRate: 148)
        ]

        let found = splits.first(where: { $0.kilometerNumber == 2 })

        #expect(found != nil)
        #expect(found!.duration == 380)
        #expect(found!.elevationChangeM == -30)
    }

    @Test("Find split by km number with nonexistent km returns nil")
    func findSplitByKmNotFound() {
        let splits = [
            Split(id: UUID(), kilometerNumber: 1, duration: 360, elevationChangeM: 50, averageHeartRate: 145)
        ]

        let found = splits.first(where: { $0.kilometerNumber == 5 })

        #expect(found == nil)
    }

    @Test("Find split in empty array returns nil")
    func findSplitEmpty() {
        let splits: [Split] = []

        let found = splits.first(where: { $0.kilometerNumber == 1 })

        #expect(found == nil)
    }

    // MARK: - Grade Calculation

    @Test("Grade calculation between two elevation points")
    func gradeCalculation() {
        let points = [
            ElevationProfilePoint(distanceKm: 0, altitudeM: 500),
            ElevationProfilePoint(distanceKm: 1, altitudeM: 600)
        ]

        // 100m gain over 1000m horizontal = 10%
        let horizM = (points[1].distanceKm - points[0].distanceKm) * 1000
        let grade = (points[1].altitudeM - points[0].altitudeM) / horizM * 100

        #expect(abs(grade - 10.0) < 0.01)
    }

    @Test("Negative grade for downhill segment")
    func negativeGrade() {
        let points = [
            ElevationProfilePoint(distanceKm: 0, altitudeM: 800),
            ElevationProfilePoint(distanceKm: 1, altitudeM: 700)
        ]

        let horizM = (points[1].distanceKm - points[0].distanceKm) * 1000
        let grade = (points[1].altitudeM - points[0].altitudeM) / horizM * 100

        #expect(abs(grade - (-10.0)) < 0.01)
    }

    @Test("Zero grade for flat segment")
    func zeroGrade() {
        let points = [
            ElevationProfilePoint(distanceKm: 0, altitudeM: 500),
            ElevationProfilePoint(distanceKm: 1, altitudeM: 500)
        ]

        let horizM = (points[1].distanceKm - points[0].distanceKm) * 1000
        let grade = (points[1].altitudeM - points[0].altitudeM) / horizM * 100

        #expect(abs(grade) < 0.01)
    }

    // MARK: - Distance Clamping

    @Test("Distance clamped to valid range")
    func distanceClamping() {
        let maxDist = 25.0
        let negativeInput = -1.0
        let beyondInput = 30.0
        let validInput = 12.5

        #expect(max(0, min(negativeInput, maxDist)) == 0)
        #expect(max(0, min(beyondInput, maxDist)) == 25.0)
        #expect(max(0, min(validInput, maxDist)) == 12.5)
    }
}
