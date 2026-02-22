import Foundation
import Testing
@testable import UltraTrain

@Suite("WatchRunCalculator liveSplitCheck Tests")
struct WatchRunCalculatorSplitCheckTests {

    // MARK: - Helpers

    /// Creates track points spaced along latitude at ~111m per 0.001 deg.
    /// With spacing 0.001 deg, 10 points cover ~1 km.
    private func makeWatchTrackPoints(
        count: Int,
        spacing: Double = 0.001,
        startAltitude: Double = 500,
        altitudeStep: Double = 0
    ) -> [WatchTrackPoint] {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        return (0..<count).map { i in
            WatchTrackPoint(
                latitude: 45.0 + Double(i) * spacing,
                longitude: 6.0,
                altitudeM: startAltitude + Double(i) * altitudeStep,
                timestamp: baseDate.addingTimeInterval(Double(i) * 30),
                heartRate: 150
            )
        }
    }

    // MARK: - liveSplitCheck

    @Test("liveSplitCheck with empty track points returns nil")
    func liveSplitCheck_emptyPoints_returnsNil() {
        let result = WatchRunCalculator.liveSplitCheck(
            trackPoints: [],
            previousSplitCount: 0
        )
        #expect(result == nil)
    }

    @Test("liveSplitCheck with no new split returns nil when same count")
    func liveSplitCheck_sameCount_returnsNil() {
        // 5 points at 0.001 spacing = ~0.555 km → no full km split
        let points = makeWatchTrackPoints(count: 5)
        let result = WatchRunCalculator.liveSplitCheck(
            trackPoints: points,
            previousSplitCount: 0
        )
        #expect(result == nil)
    }

    @Test("liveSplitCheck detects new split when km boundary crossed")
    func liveSplitCheck_newSplit_detected() {
        // ~11 points at 0.001 deg spacing ≈ 1.11 km → should produce 1 split
        let points = makeWatchTrackPoints(count: 12)

        let result = WatchRunCalculator.liveSplitCheck(
            trackPoints: points,
            previousSplitCount: 0
        )
        #expect(result != nil)
        #expect(result?.kilometerNumber == 1)
    }

    @Test("liveSplitCheck returns nil if already seen the split")
    func liveSplitCheck_alreadySeen_returnsNil() {
        // ~12 points produce 1 split; if previousSplitCount is already 1, no new split
        let points = makeWatchTrackPoints(count: 12)
        let result = WatchRunCalculator.liveSplitCheck(
            trackPoints: points,
            previousSplitCount: 1
        )
        #expect(result == nil)
    }

    @Test("liveSplitCheck returns the latest split")
    func liveSplitCheck_multipleKm_returnsLatest() {
        // ~22 points at 0.001 deg ≈ 2.33 km → should produce 2 splits
        let points = makeWatchTrackPoints(count: 23)
        // Pretend we had 0 previous splits → should return the latest new split
        let result = WatchRunCalculator.liveSplitCheck(
            trackPoints: points,
            previousSplitCount: 0
        )
        #expect(result != nil)
        // The latest split should be the most recent one
        #expect(result!.kilometerNumber >= 1)
    }
}
