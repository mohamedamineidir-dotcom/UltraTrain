import Foundation
import Testing
@testable import UltraTrain

@Suite("ElevationPaceOverlayCalculator Tests")
struct ElevationPaceOverlayCalculatorTests {

    // MARK: - Helpers

    private func makeProfile(_ points: [(km: Double, alt: Double)]) -> [ElevationProfilePoint] {
        points.map { ElevationProfilePoint(distanceKm: $0.km, altitudeM: $0.alt) }
    }

    private func makeSplits(_ durations: [Double]) -> [Split] {
        durations.enumerated().map { index, duration in
            Split(
                id: UUID(),
                kilometerNumber: index + 1,
                duration: duration,
                elevationChangeM: 0,
                averageHeartRate: nil
            )
        }
    }

    private func makeCheckpoints(_ points: [(name: String, km: Double, elev: Double, aid: Bool)]) -> [Checkpoint] {
        points.map {
            Checkpoint(
                id: UUID(),
                name: $0.name,
                distanceFromStartKm: $0.km,
                elevationM: $0.elev,
                hasAidStation: $0.aid
            )
        }
    }

    private func makeCheckpointSplits(
        _ splits: [(name: String, distKm: Double, segKm: Double, segGain: Double, time: TimeInterval)]
    ) -> [CheckpointSplit] {
        splits.map {
            CheckpointSplit(
                id: UUID(),
                checkpointId: UUID(),
                checkpointName: $0.name,
                distanceFromStartKm: $0.distKm,
                segmentDistanceKm: $0.segKm,
                segmentElevationGainM: $0.segGain,
                hasAidStation: false,
                optimisticTime: $0.time * 0.9,
                expectedTime: $0.time,
                conservativeTime: $0.time * 1.1
            )
        }
    }

    // MARK: - Elevation Normalization

    @Test("Normalized elevation values are in 0...1 range")
    func normalizedElevationRange() {
        let profile = makeProfile([(km: 0, alt: 500), (km: 5, alt: 1500), (km: 10, alt: 800)])
        let splits = makeSplits([360, 420, 380])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        for point in result.elevation {
            #expect(point.normalizedAltitude >= 0)
            #expect(point.normalizedAltitude <= 1)
        }
    }

    @Test("Lowest altitude normalizes to 0, highest to 1")
    func elevationMinMaxNormalization() {
        let profile = makeProfile([(km: 0, alt: 200), (km: 5, alt: 800), (km: 10, alt: 500)])
        let splits = makeSplits([360])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        let minNorm = result.elevation.min(by: { $0.altitudeM < $1.altitudeM })!.normalizedAltitude
        let maxNorm = result.elevation.max(by: { $0.altitudeM < $1.altitudeM })!.normalizedAltitude
        #expect(minNorm == 0.0)
        #expect(maxNorm == 1.0)
    }

    // MARK: - Pace Normalization

    @Test("Faster pace normalizes to higher value (inverted)")
    func paceInversion() {
        let profile = makeProfile([(km: 0, alt: 100)])
        let splits = makeSplits([300, 600])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        let fasterPoint = result.pace.first(where: { $0.paceSecondsPerKm == 300 })!
        let slowerPoint = result.pace.first(where: { $0.paceSecondsPerKm == 600 })!
        #expect(fasterPoint.normalizedPace > slowerPoint.normalizedPace)
    }

    @Test("Normalized pace values are in 0...1 range")
    func normalizedPaceRange() {
        let profile = makeProfile([(km: 0, alt: 100)])
        let splits = makeSplits([300, 400, 500, 360, 450])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        for point in result.pace {
            #expect(point.normalizedPace >= 0)
            #expect(point.normalizedPace <= 1)
        }
    }

    // MARK: - Pace Categories

    @Test("Pace categories classify correctly relative to average")
    func paceCategoryClassification() {
        let profile = makeProfile([(km: 0, alt: 100)])
        // Average = 400. 300 < 400*0.95=380 → faster. 500 > 400*1.05=420 → slower. 400 = average.
        let splits = makeSplits([300, 400, 500])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        let fastest = result.pace.first(where: { $0.paceSecondsPerKm == 300 })!
        let average = result.pace.first(where: { $0.paceSecondsPerKm == 400 })!
        let slowest = result.pace.first(where: { $0.paceSecondsPerKm == 500 })!

        #expect(fastest.paceCategory == .faster)
        #expect(average.paceCategory == .average)
        #expect(slowest.paceCategory == .slower)
    }

    @Test("Identical paces all classify as average")
    func identicalPacesAllAverage() {
        let profile = makeProfile([(km: 0, alt: 100)])
        let splits = makeSplits([360, 360, 360])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        for point in result.pace {
            #expect(point.paceCategory == .average)
        }
    }

    // MARK: - Edge Cases

    @Test("Empty splits produce empty pace points")
    func emptySplits() {
        let profile = makeProfile([(km: 0, alt: 100), (km: 5, alt: 500)])
        let splits: [Split] = []

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        #expect(result.elevation.count == 2)
        #expect(result.pace.isEmpty)
    }

    @Test("Empty elevation profile produces empty elevation points")
    func emptyElevation() {
        let profile: [ElevationProfilePoint] = []
        let splits = makeSplits([360])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        #expect(result.elevation.isEmpty)
        #expect(result.pace.count == 1)
    }

    @Test("Flat elevation normalizes gracefully without divide by zero")
    func flatElevation() {
        let profile = makeProfile([(km: 0, alt: 500), (km: 5, alt: 500), (km: 10, alt: 500)])
        let splits = makeSplits([360])

        let result = ElevationPaceOverlayCalculator.buildOverlay(
            elevationProfile: profile,
            splits: splits
        )

        for point in result.elevation {
            #expect(point.normalizedAltitude == 0.5)
        }
    }

    // MARK: - Race Course Overlay

    @Test("Race course overlay builds from checkpoints and splits")
    func raceCourseOverlay() {
        let checkpoints = makeCheckpoints([
            (name: "Start", km: 0, elev: 500, aid: false),
            (name: "CP1", km: 10, elev: 1200, aid: true),
            (name: "CP2", km: 25, elev: 800, aid: true),
            (name: "Finish", km: 40, elev: 500, aid: false)
        ])

        let splits = makeCheckpointSplits([
            (name: "CP1", distKm: 10, segKm: 10, segGain: 700, time: 4200),
            (name: "CP2", distKm: 25, segKm: 15, segGain: 100, time: 5400),
            (name: "Finish", distKm: 40, segKm: 15, segGain: 0, time: 4800)
        ])

        let result = ElevationPaceOverlayCalculator.buildRaceCourseOverlay(
            checkpoints: checkpoints,
            checkpointSplits: splits
        )

        #expect(result.elevation.count == 4)
        #expect(result.pace.count == 3)
    }

    @Test("Segment paces derived correctly from checkpoint splits")
    func segmentPaceCalculation() {
        let splits = makeCheckpointSplits([
            (name: "CP1", distKm: 10, segKm: 10, segGain: 0, time: 3600)
        ])

        let paces = ElevationPaceOverlayCalculator.segmentPaces(from: splits)
        #expect(paces.count == 1)
        #expect(paces[0].paceSecondsPerKm == 360) // 3600s / 10km
        #expect(paces[0].distanceKm == 5) // midpoint of 0-10km segment
    }

    @Test("Zero-distance segments are filtered out")
    func zeroDistanceSegmentFiltered() {
        let splits = makeCheckpointSplits([
            (name: "Start", distKm: 0, segKm: 0, segGain: 0, time: 0),
            (name: "CP1", distKm: 10, segKm: 10, segGain: 0, time: 3600)
        ])

        let paces = ElevationPaceOverlayCalculator.segmentPaces(from: splits)
        #expect(paces.count == 1)
    }
}
