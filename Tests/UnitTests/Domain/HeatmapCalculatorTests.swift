import Foundation
import Testing
@testable import UltraTrain

@Suite("Heatmap Calculator Tests")
struct HeatmapCalculatorTests {

    // MARK: - Helpers

    private func makePoint(lat: Double, lon: Double) -> TrackPoint {
        TrackPoint(
            latitude: lat,
            longitude: lon,
            altitudeM: 100,
            timestamp: Date(),
            heartRate: nil
        )
    }

    // MARK: - Tests

    @Test("Empty tracks returns empty cells")
    func emptyTracks() {
        let result = HeatmapCalculator.compute(tracks: [])
        #expect(result.isEmpty)
    }

    @Test("Single point produces one cell")
    func singlePoint() {
        let point = makePoint(lat: 48.0, lon: 2.0)
        let result = HeatmapCalculator.compute(tracks: [[point]])
        #expect(result.count == 1)
        #expect(result[0].count == 1)
    }

    @Test("Two identical points produce one cell with count 2")
    func identicalPoints() {
        let p1 = makePoint(lat: 48.0, lon: 2.0)
        let p2 = makePoint(lat: 48.0, lon: 2.0)
        let result = HeatmapCalculator.compute(tracks: [[p1, p2]])
        #expect(result.count == 1)
        #expect(result[0].count == 2)
    }

    @Test("Points in different grid cells produce multiple cells")
    func differentCells() {
        // Points ~500m apart (0.005 deg lat ~ 555m) with 50m grid -> separate cells
        let p1 = makePoint(lat: 48.0, lon: 2.0)
        let p2 = makePoint(lat: 48.005, lon: 2.0)
        let result = HeatmapCalculator.compute(tracks: [[p1, p2]], gridSizeMeters: 50)
        #expect(result.count == 2)
    }

    @Test("Maximum cell has normalized intensity of 1.0")
    func normalizedIntensity() {
        // Three points: two in one cell, one in another -> max cell = 2 -> normalized = 1.0
        let p1 = makePoint(lat: 48.0, lon: 2.0)
        let p2 = makePoint(lat: 48.0, lon: 2.0)
        let p3 = makePoint(lat: 48.005, lon: 2.0)
        let result = HeatmapCalculator.compute(tracks: [[p1, p2, p3]], gridSizeMeters: 50)

        let maxCell = result.max(by: { $0.count < $1.count })!
        #expect(maxCell.normalizedIntensity == 1.0)

        let minCell = result.min(by: { $0.count < $1.count })!
        #expect(minCell.normalizedIntensity == 0.5)
    }
}
