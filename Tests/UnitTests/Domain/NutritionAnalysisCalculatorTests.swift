import Foundation
import Testing
@testable import UltraTrain

@Suite("NutritionAnalysis Calculator Tests")
struct NutritionAnalysisCalculatorTests {

    // MARK: - Helpers

    private func makeRun(
        duration: TimeInterval = 7200,
        splits: [Split]? = nil,
        intakeLog: [NutritionIntakeEntry] = []
    ) -> CompletedRun {
        let defaultSplits = splits ?? (1...20).map { km in
            Split(
                id: UUID(),
                kilometerNumber: km,
                duration: 360,
                elevationChangeM: 0,
                averageHeartRate: 150
            )
        }
        var run = CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: 20,
            elevationGainM: 500,
            elevationLossM: 450,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: defaultSplits,
            linkedSessionId: nil,
            notes: nil,
            pausedDuration: 0
        )
        run.nutritionIntakeLog = intakeLog
        return run
    }

    private func makeEntry(
        type: NutritionReminderType = .fuel,
        status: NutritionIntakeStatus = .taken,
        elapsed: TimeInterval
    ) -> NutritionIntakeEntry {
        NutritionIntakeEntry(
            reminderType: type,
            status: status,
            elapsedTimeSeconds: elapsed,
            message: "Test"
        )
    }

    // MARK: - Nil Cases

    @Test("Returns nil when no intake log")
    func nilWhenNoLog() {
        let run = makeRun()
        let result = NutritionAnalysisCalculator.analyze(run: run)
        #expect(result == nil)
    }

    // MARK: - Adherence

    @Test("Adherence 100% when all taken")
    func fullAdherence() {
        let log = [
            makeEntry(status: .taken, elapsed: 1200),
            makeEntry(status: .taken, elapsed: 2400),
            makeEntry(status: .taken, elapsed: 3600)
        ]
        let adherence = NutritionAnalysisCalculator.calculateAdherence(log: log)
        #expect(adherence == 100)
    }

    @Test("Adherence 50% when half skipped")
    func halfAdherence() {
        let log = [
            makeEntry(status: .taken, elapsed: 1200),
            makeEntry(status: .skipped, elapsed: 2400)
        ]
        let adherence = NutritionAnalysisCalculator.calculateAdherence(log: log)
        #expect(adherence == 50)
    }

    @Test("Adherence ignores pending entries")
    func adherenceIgnoresPending() {
        let log = [
            makeEntry(status: .taken, elapsed: 1200),
            makeEntry(status: .pending, elapsed: 2400)
        ]
        let adherence = NutritionAnalysisCalculator.calculateAdherence(log: log)
        #expect(adherence == 100)
    }

    // MARK: - Timeline Events

    @Test("Timeline events match intake count")
    func timelineMatchesCount() {
        let log = [
            makeEntry(type: .hydration, elapsed: 1200),
            makeEntry(type: .fuel, elapsed: 2400),
            makeEntry(type: .electrolyte, elapsed: 3600)
        ]
        let run = makeRun(intakeLog: log)
        let events = NutritionAnalysisCalculator.buildTimelineEvents(run: run)

        #expect(events.count == 3)
        #expect(events[0].type == .hydration)
        #expect(events[1].type == .fuel)
        #expect(events[2].type == .electrolyte)
    }

    // MARK: - Calorie Estimate

    @Test("Fuel intakes contribute calories")
    func fuelCalories() {
        let log = [
            makeEntry(type: .fuel, status: .taken, elapsed: 1200),
            makeEntry(type: .fuel, status: .taken, elapsed: 2400),
            makeEntry(type: .hydration, status: .taken, elapsed: 1800)
        ]
        let calories = NutritionAnalysisCalculator.estimateTotalCalories(log: log)
        #expect(calories == 50)
    }

    @Test("Skipped intakes do not contribute calories")
    func skippedNoCalories() {
        let log = [
            makeEntry(type: .fuel, status: .skipped, elapsed: 1200),
            makeEntry(type: .fuel, status: .taken, elapsed: 2400)
        ]
        let calories = NutritionAnalysisCalculator.estimateTotalCalories(log: log)
        #expect(calories == 25)
    }

    // MARK: - Full Analysis

    @Test("Full analysis returns complete result")
    func fullAnalysis() {
        let log = [
            makeEntry(type: .hydration, status: .taken, elapsed: 1200),
            makeEntry(type: .fuel, status: .taken, elapsed: 2400),
            makeEntry(type: .fuel, status: .skipped, elapsed: 3600)
        ]
        let run = makeRun(intakeLog: log)
        let result = NutritionAnalysisCalculator.analyze(run: run)

        #expect(result != nil)
        #expect(result!.timelineEvents.count == 3)
        #expect(result!.adherencePercent > 0)
        #expect(result!.totalCaloriesConsumed == 25)
    }
}
