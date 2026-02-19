import Foundation
import Testing
@testable import UltraTrain

@Suite("NutritionIntakeSummary Tests")
struct NutritionIntakeSummaryTests {

    private func makeEntry(
        type: NutritionReminderType,
        status: NutritionIntakeStatus,
        elapsed: TimeInterval = 0
    ) -> NutritionIntakeEntry {
        NutritionIntakeEntry(
            reminderType: type,
            status: status,
            elapsedTimeSeconds: elapsed,
            message: "\(type.rawValue) reminder"
        )
    }

    @Test("Empty entries return zero counts")
    func emptyEntries() {
        let summary = NutritionIntakeSummary(entries: [])

        #expect(summary.takenCount == 0)
        #expect(summary.skippedCount == 0)
        #expect(summary.pendingCount == 0)
        #expect(summary.hydrationTakenCount == 0)
        #expect(summary.fuelTakenCount == 0)
        #expect(summary.electrolyteTakenCount == 0)
    }

    @Test("Counts taken entries correctly")
    func takenCounts() {
        let entries = [
            makeEntry(type: .hydration, status: .taken),
            makeEntry(type: .hydration, status: .taken),
            makeEntry(type: .fuel, status: .taken),
            makeEntry(type: .electrolyte, status: .taken),
        ]
        let summary = NutritionIntakeSummary(entries: entries)

        #expect(summary.takenCount == 4)
        #expect(summary.hydrationTakenCount == 2)
        #expect(summary.fuelTakenCount == 1)
        #expect(summary.electrolyteTakenCount == 1)
    }

    @Test("Counts skipped entries correctly")
    func skippedCounts() {
        let entries = [
            makeEntry(type: .hydration, status: .skipped),
            makeEntry(type: .fuel, status: .skipped),
        ]
        let summary = NutritionIntakeSummary(entries: entries)

        #expect(summary.skippedCount == 2)
        #expect(summary.takenCount == 0)
    }

    @Test("Counts pending entries correctly")
    func pendingCounts() {
        let entries = [
            makeEntry(type: .hydration, status: .pending),
            makeEntry(type: .fuel, status: .pending),
            makeEntry(type: .electrolyte, status: .pending),
        ]
        let summary = NutritionIntakeSummary(entries: entries)

        #expect(summary.pendingCount == 3)
        #expect(summary.takenCount == 0)
        #expect(summary.skippedCount == 0)
    }

    @Test("Mixed statuses counted correctly")
    func mixedStatuses() {
        let entries = [
            makeEntry(type: .hydration, status: .taken, elapsed: 1200),
            makeEntry(type: .hydration, status: .skipped, elapsed: 2400),
            makeEntry(type: .hydration, status: .pending, elapsed: 3600),
            makeEntry(type: .fuel, status: .taken, elapsed: 2700),
            makeEntry(type: .fuel, status: .taken, elapsed: 5400),
            makeEntry(type: .electrolyte, status: .skipped, elapsed: 3600),
        ]
        let summary = NutritionIntakeSummary(entries: entries)

        #expect(summary.takenCount == 3)
        #expect(summary.skippedCount == 2)
        #expect(summary.pendingCount == 1)
        #expect(summary.hydrationTakenCount == 1)
        #expect(summary.fuelTakenCount == 2)
        #expect(summary.electrolyteTakenCount == 0)
    }
}
