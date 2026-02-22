import Foundation
import Testing
@testable import UltraTrain

@Suite("Monthly Volume Calculator Tests")
struct MonthlyVolumeCalculatorTests {

    // MARK: - Helpers

    private func makeRun(
        date: Date = .now,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )
    }

    private func date(year: Int, month: Int, day: Int = 15) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }

    // MARK: - Tests

    @Test("Empty runs returns empty result")
    func emptyRuns() {
        let result = MonthlyVolumeCalculator.compute(from: [])
        #expect(result.isEmpty)
    }

    @Test("Single run produces one month volume")
    func singleRun() {
        let run = makeRun(date: date(year: 2025, month: 6), distanceKm: 12, elevationGainM: 300)
        let result = MonthlyVolumeCalculator.compute(from: [run])
        #expect(result.count == 1)
        #expect(result[0].distanceKm == 12)
        #expect(result[0].elevationGainM == 300)
        #expect(result[0].runCount == 1)
    }

    @Test("Multiple runs in the same month are aggregated")
    func sameMonthAggregated() {
        let runs = [
            makeRun(date: date(year: 2025, month: 3, day: 5), distanceKm: 10, elevationGainM: 200, duration: 3600),
            makeRun(date: date(year: 2025, month: 3, day: 20), distanceKm: 15, elevationGainM: 400, duration: 5400),
        ]
        let result = MonthlyVolumeCalculator.compute(from: runs)
        #expect(result.count == 1)
        #expect(result[0].distanceKm == 25)
        #expect(result[0].elevationGainM == 600)
        #expect(result[0].runCount == 2)
        #expect(result[0].duration == 9000)
    }

    @Test("Runs across different months produce separate volumes")
    func differentMonths() {
        let runs = [
            makeRun(date: date(year: 2025, month: 1), distanceKm: 10),
            makeRun(date: date(year: 2025, month: 2), distanceKm: 20),
            makeRun(date: date(year: 2025, month: 3), distanceKm: 30),
        ]
        let result = MonthlyVolumeCalculator.compute(from: runs)
        #expect(result.count == 3)
    }

    @Test("Results are sorted by month ascending")
    func sortedByMonth() {
        let runs = [
            makeRun(date: date(year: 2025, month: 5), distanceKm: 50),
            makeRun(date: date(year: 2025, month: 1), distanceKm: 10),
            makeRun(date: date(year: 2025, month: 3), distanceKm: 30),
        ]
        let result = MonthlyVolumeCalculator.compute(from: runs)
        #expect(result.count == 3)
        #expect(result[0].month < result[1].month)
        #expect(result[1].month < result[2].month)
    }
}
