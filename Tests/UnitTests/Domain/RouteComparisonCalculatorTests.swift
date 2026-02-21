import Foundation
import Testing
@testable import UltraTrain

@Suite("RouteComparisonCalculator Tests")
struct RouteComparisonCalculatorTests {

    private func makePoint(
        lat: Double,
        lon: Double,
        alt: Double = 0
    ) -> TrackPoint {
        TrackPoint(
            latitude: lat,
            longitude: lon,
            altitudeM: alt,
            timestamp: .now
        )
    }

    @Test("Identical routes produce zero deviation")
    func identicalRoutes() {
        let route = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.001, lon: 6.001),
            makePoint(lat: 45.002, lon: 6.002)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: route,
            planned: route
        )
        #expect(result.maxDeviationMeters < 1)
        #expect(result.averageDeviationMeters < 1)
        #expect(result.deviationSegments.isEmpty)
    }

    @Test("Empty actual route returns zero comparison")
    func emptyActual() {
        let planned = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.001, lon: 6.001)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: [],
            planned: planned
        )
        #expect(result.maxDeviationMeters == 0)
        #expect(result.averageDeviationMeters == 0)
    }

    @Test("Empty planned route returns zero comparison")
    func emptyPlanned() {
        let actual = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.001, lon: 6.001)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: actual,
            planned: []
        )
        #expect(result.maxDeviationMeters == 0)
    }

    @Test("Parallel offset route produces consistent deviation")
    func parallelOffset() {
        let planned = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.01, lon: 6.0)
        ]
        // Offset by ~0.001 degrees longitude (roughly 70-80m at lat 45)
        let actual = [
            makePoint(lat: 45.0, lon: 6.001),
            makePoint(lat: 45.01, lon: 6.001)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: actual,
            planned: planned
        )
        #expect(result.averageDeviationMeters > 50)
        #expect(result.averageDeviationMeters < 100)
    }

    @Test("Single point routes handle gracefully")
    func singlePointRoutes() {
        let p = makePoint(lat: 45.0, lon: 6.0)
        let result = RouteComparisonCalculator.compare(
            actual: [p],
            planned: [p]
        )
        #expect(result.maxDeviationMeters < 1)
    }

    @Test("Distance totals are computed")
    func distanceTotals() {
        let planned = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.01, lon: 6.0),
            makePoint(lat: 45.02, lon: 6.0)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: planned,
            planned: planned
        )
        #expect(result.totalActualDistanceKm > 0)
        #expect(result.totalPlannedDistanceKm > 0)
        #expect(
            abs(result.totalActualDistanceKm - result.totalPlannedDistanceKm)
                < 0.01
        )
    }

    @Test("Significant deviation segments detected")
    func significantSegments() {
        let planned = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.01, lon: 6.0)
        ]
        // Way off course - offset by ~0.01 degrees (~700m)
        let actual = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.003, lon: 6.01),
            makePoint(lat: 45.005, lon: 6.01),
            makePoint(lat: 45.01, lon: 6.0)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: actual,
            planned: planned
        )
        #expect(!result.deviationSegments.isEmpty)
        #expect(result.deviationSegments.allSatisfy { $0.isSignificant })
    }

    @Test("Max deviation is at least as large as average")
    func maxVsAverage() {
        let planned = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.01, lon: 6.0)
        ]
        let actual = [
            makePoint(lat: 45.0, lon: 6.0),
            makePoint(lat: 45.005, lon: 6.005),
            makePoint(lat: 45.01, lon: 6.0)
        ]
        let result = RouteComparisonCalculator.compare(
            actual: actual,
            planned: planned
        )
        #expect(result.maxDeviationMeters >= result.averageDeviationMeters)
    }
}
