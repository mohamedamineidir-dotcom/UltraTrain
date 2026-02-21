import Foundation
import Testing
@testable import UltraTrain

@Suite("WeeklyZoneDistributionCalculator Tests")
struct WeeklyZoneDistributionCalculatorTests {

    // MARK: - Helpers

    private func makeRun(
        date: Date,
        trackPoints: [TrackPoint] = []
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 200,
            duration: 3600,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: trackPoints,
            splits: [],
            pausedDuration: 0
        )
    }

    private func makeTrackPointsWithHR(
        heartRates: [Int],
        intervalSeconds: TimeInterval = 30
    ) -> [TrackPoint] {
        heartRates.enumerated().map { index, hr in
            TrackPoint(
                latitude: Double(index) * 0.0001,
                longitude: 0,
                altitudeM: 500,
                timestamp: Date.now.addingTimeInterval(Double(index) * intervalSeconds),
                heartRate: hr
            )
        }
    }

    // MARK: - Tests

    @Test("Empty runs returns zero distribution")
    func emptyRuns() {
        let result = WeeklyZoneDistributionCalculator.calculate(
            runs: [],
            weekStartDate: Date.now.startOfWeek,
            maxHeartRate: 200
        )

        #expect(result.totalDurationWithHR == 0)
        #expect(result.distributions.count == 5)
        #expect(result.distributions.allSatisfy { $0.durationSeconds == 0 })
    }

    @Test("Single run produces zone distribution")
    func singleRun() {
        let weekStart = Date.now.startOfWeek
        let runDate = weekStart.addingTimeInterval(86400)

        let points = makeTrackPointsWithHR(
            heartRates: [130, 130, 130, 130, 130, 170, 170, 170, 170, 170]
        )

        let run = makeRun(date: runDate, trackPoints: points)
        let result = WeeklyZoneDistributionCalculator.calculate(
            runs: [run],
            weekStartDate: weekStart,
            maxHeartRate: 200
        )

        #expect(result.totalDurationWithHR > 0)
        let nonZero = result.distributions.filter { $0.durationSeconds > 0 }
        #expect(!nonZero.isEmpty)
    }

    @Test("Runs outside the week are excluded")
    func weekFiltering() {
        let weekStart = Date.now.startOfWeek
        let outsideDate = weekStart.addingTimeInterval(-86400)

        let points = makeTrackPointsWithHR(heartRates: [150, 150, 150])
        let outsideRun = makeRun(date: outsideDate, trackPoints: points)

        let result = WeeklyZoneDistributionCalculator.calculate(
            runs: [outsideRun],
            weekStartDate: weekStart,
            maxHeartRate: 200
        )

        #expect(result.totalDurationWithHR == 0)
    }

    @Test("Custom thresholds are respected")
    func customThresholds() {
        let weekStart = Date.now.startOfWeek
        let runDate = weekStart.addingTimeInterval(86400)

        // All HR at 150 bpm
        let points = makeTrackPointsWithHR(
            heartRates: [150, 150, 150, 150, 150]
        )
        let run = makeRun(date: runDate, trackPoints: points)

        // Default: 150/200 = 75% → Zone 3
        let defaultResult = WeeklyZoneDistributionCalculator.calculate(
            runs: [run],
            weekStartDate: weekStart,
            maxHeartRate: 200
        )

        // Custom: 150 is between 140 and 155 → Zone 3
        let customResult = WeeklyZoneDistributionCalculator.calculate(
            runs: [run],
            weekStartDate: weekStart,
            maxHeartRate: 200,
            customThresholds: [100, 130, 160, 180]
        )

        // With custom [100,130,160,180], 150 ≤ 160 → zone 3
        let defaultZone3 = defaultResult.distributions.first { $0.zone == 3 }
        let customZone3 = customResult.distributions.first { $0.zone == 3 }
        #expect(defaultZone3?.durationSeconds ?? 0 > 0)
        #expect(customZone3?.durationSeconds ?? 0 > 0)
    }

    @Test("Multiple runs aggregate zone durations")
    func multipleRuns() {
        let weekStart = Date.now.startOfWeek

        let points1 = makeTrackPointsWithHR(heartRates: [130, 130, 130, 130])
        let points2 = makeTrackPointsWithHR(heartRates: [170, 170, 170, 170])

        let run1 = makeRun(date: weekStart.addingTimeInterval(86400), trackPoints: points1)
        let run2 = makeRun(date: weekStart.addingTimeInterval(172800), trackPoints: points2)

        let result = WeeklyZoneDistributionCalculator.calculate(
            runs: [run1, run2],
            weekStartDate: weekStart,
            maxHeartRate: 200
        )

        #expect(result.totalDurationWithHR > 0)
        let totalPct = result.distributions.reduce(0) { $0 + $1.percentage }
        #expect(totalPct > 99 && totalPct < 101)
    }
}
