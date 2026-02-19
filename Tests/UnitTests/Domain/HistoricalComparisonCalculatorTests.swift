import Foundation
import Testing
@testable import UltraTrain

@Suite("HistoricalComparison Calculator Tests")
struct HistoricalComparisonCalculatorTests {

    // MARK: - Helpers

    private func makeSplits(paces: [Double]) -> [Split] {
        paces.enumerated().map { index, pace in
            Split(
                id: UUID(),
                kilometerNumber: index + 1,
                duration: pace,
                elevationChangeM: 0,
                averageHeartRate: 150
            )
        }
    }

    private func makeRun(
        distanceKm: Double = 10,
        elevationGainM: Double = 300,
        duration: TimeInterval = 3600,
        avgPace: Double = 360,
        splits: [Split]? = nil,
        date: Date = .now
    ) -> CompletedRun {
        let defaultSplits = splits ?? makeSplits(paces: Array(repeating: avgPace, count: Int(distanceKm)))
        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 250,
            duration: duration,
            averageHeartRate: 155,
            maxHeartRate: 180,
            averagePaceSecondsPerKm: avgPace,
            gpsTrack: [],
            splits: defaultSplits,
            linkedSessionId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    // MARK: - Split PRs

    @Test("Identifies split PRs when current split is faster")
    func findsSplitPRs() {
        let current = makeRun(splits: makeSplits(paces: [300, 310, 320]))
        let previous = makeRun(splits: makeSplits(paces: [350, 305, 330]))

        let prs = HistoricalComparisonCalculator.findSplitPRs(run: current, recentRuns: [previous])

        #expect(prs.count == 2)
        #expect(prs.contains { $0.kilometerNumber == 1 })
        #expect(prs.contains { $0.kilometerNumber == 3 })
    }

    @Test("No PRs when current run is slower")
    func noPRsWhenSlower() {
        let current = makeRun(splits: makeSplits(paces: [400, 410, 420]))
        let previous = makeRun(splits: makeSplits(paces: [350, 360, 370]))

        let prs = HistoricalComparisonCalculator.findSplitPRs(run: current, recentRuns: [previous])
        #expect(prs.isEmpty)
    }

    @Test("No PRs when no recent runs")
    func noPRsNoHistory() {
        let current = makeRun()
        let prs = HistoricalComparisonCalculator.findSplitPRs(run: current, recentRuns: [])
        #expect(prs.isEmpty)
    }

    // MARK: - Pace Trend

    @Test("Pace trend improving when significantly faster")
    func trendImproving() {
        let current = makeRun(avgPace: 330)
        let recent = (0..<5).map { i in
            makeRun(avgPace: 360, date: .now.addingTimeInterval(Double(-i * 86400)))
        }

        let trend = HistoricalComparisonCalculator.calculatePaceTrend(run: current, recentRuns: recent)
        #expect(trend == .improving)
    }

    @Test("Pace trend declining when significantly slower")
    func trendDeclining() {
        let current = makeRun(avgPace: 400)
        let recent = (0..<5).map { i in
            makeRun(avgPace: 360, date: .now.addingTimeInterval(Double(-i * 86400)))
        }

        let trend = HistoricalComparisonCalculator.calculatePaceTrend(run: current, recentRuns: recent)
        #expect(trend == .declining)
    }

    @Test("Pace trend stable within 3%")
    func trendStable() {
        let current = makeRun(avgPace: 365)
        let recent = (0..<5).map { i in
            makeRun(avgPace: 360, date: .now.addingTimeInterval(Double(-i * 86400)))
        }

        let trend = HistoricalComparisonCalculator.calculatePaceTrend(run: current, recentRuns: recent)
        #expect(trend == .stable)
    }

    @Test("Pace trend stable with no recent runs")
    func trendStableNoHistory() {
        let current = makeRun()
        let trend = HistoricalComparisonCalculator.calculatePaceTrend(run: current, recentRuns: [])
        #expect(trend == .stable)
    }

    // MARK: - Badges

    @Test("Badge for longest run")
    func longestRunBadge() {
        let current = makeRun(distanceKm: 30)
        let recent = [makeRun(distanceKm: 20), makeRun(distanceKm: 25)]

        let badges = HistoricalComparisonCalculator.calculateBadges(run: current, recentRuns: recent)
        #expect(badges.contains { $0.title == "Longest Run" })
    }

    @Test("Badge for most elevation")
    func mostElevationBadge() {
        let current = makeRun(elevationGainM: 1500)
        let recent = [makeRun(elevationGainM: 800), makeRun(elevationGainM: 1000)]

        let badges = HistoricalComparisonCalculator.calculateBadges(run: current, recentRuns: recent)
        #expect(badges.contains { $0.title == "Most Elevation" })
    }

    @Test("Badge for fastest pace")
    func fastestPaceBadge() {
        let current = makeRun(avgPace: 280)
        let recent = [makeRun(avgPace: 300), makeRun(avgPace: 320)]

        let badges = HistoricalComparisonCalculator.calculateBadges(run: current, recentRuns: recent)
        #expect(badges.contains { $0.title == "Fastest Pace" })
    }

    @Test("No badges when run is not exceptional")
    func noBadges() {
        let current = makeRun(distanceKm: 10, elevationGainM: 300, avgPace: 360)
        let recent = [makeRun(distanceKm: 15, elevationGainM: 500, avgPace: 340)]

        let badges = HistoricalComparisonCalculator.calculateBadges(run: current, recentRuns: recent)
        let nonConsistencyBadges = badges.filter { $0.title != "Consistency King" }
        #expect(nonConsistencyBadges.isEmpty)
    }

    // MARK: - Full Compare

    @Test("Compare returns complete result")
    func fullCompare() {
        let current = makeRun(distanceKm: 15, avgPace: 340)
        let recent = [makeRun(distanceKm: 10, avgPace: 360)]

        let result = HistoricalComparisonCalculator.compare(run: current, recentRuns: recent)

        #expect(result.paceTrend == .improving)
        #expect(result.badges.contains { $0.title == "Longest Run" })
    }
}
