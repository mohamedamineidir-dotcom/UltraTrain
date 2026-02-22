import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Calendar Heatmap Calculator Tests")
struct TrainingCalendarHeatmapCalculatorTests {

    // MARK: - Helpers

    private func makeRun(
        date: Date = .now,
        distanceKm: Double = 10,
        duration: TimeInterval = 3600
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: 200,
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

    // MARK: - Tests

    @Test("Empty runs returns all rest days for the range")
    func emptyRuns() {
        let result = TrainingCalendarHeatmapCalculator.compute(runs: [], weeksToShow: 4)
        #expect(result.count == 28)
        #expect(result.allSatisfy { $0.intensity == .rest })
    }

    @Test("Short run under 45 minutes produces easy intensity")
    func shortRunEasy() {
        // 30 minutes = 1800s -> easy
        let run = makeRun(date: .now, duration: 1800)
        let result = TrainingCalendarHeatmapCalculator.compute(runs: [run], weeksToShow: 1)
        let today = result.last!
        #expect(today.intensity == .easy)
    }

    @Test("Moderate run of 60 minutes produces moderate intensity")
    func moderateRunModerate() {
        // 60 minutes = 3600s -> moderate (between 2700 and 5400)
        let run = makeRun(date: .now, duration: 3600)
        let result = TrainingCalendarHeatmapCalculator.compute(runs: [run], weeksToShow: 1)
        let today = result.last!
        #expect(today.intensity == .moderate)
    }

    @Test("Long run of 2.5 hours produces hard intensity")
    func longRunHard() {
        // 2.5h = 9000s -> hard (between 5400 and 9000)
        // Actually the boundary is at 9000 which goes to veryHard, use 8999
        let run = makeRun(date: .now, duration: 8999)
        let result = TrainingCalendarHeatmapCalculator.compute(runs: [run], weeksToShow: 1)
        let today = result.last!
        #expect(today.intensity == .hard)
    }

    @Test("Very long run of 3 hours produces very hard intensity")
    func veryLongRunVeryHard() {
        // 3h = 10800s -> veryHard (>= 9000)
        let run = makeRun(date: .now, duration: 10800)
        let result = TrainingCalendarHeatmapCalculator.compute(runs: [run], weeksToShow: 1)
        let today = result.last!
        #expect(today.intensity == .veryHard)
    }

    @Test("Multiple runs on the same day have their durations summed")
    func multipleRunsSameDay() {
        // Two easy runs (20min each = 1200s) -> total 2400s -> still easy
        let run1 = makeRun(date: .now, duration: 1200)
        let run2 = makeRun(date: .now, duration: 1200)
        let result = TrainingCalendarHeatmapCalculator.compute(runs: [run1, run2], weeksToShow: 1)
        let today = result.last!
        #expect(today.runCount == 2)
        #expect(today.totalDuration == 2400)
        #expect(today.intensity == .easy)
    }
}
