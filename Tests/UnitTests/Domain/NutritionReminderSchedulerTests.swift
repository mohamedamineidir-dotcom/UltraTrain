import Foundation
import Testing
@testable import UltraTrain

@Suite("NutritionReminderScheduler Tests")
struct NutritionReminderSchedulerTests {

    // MARK: - Helpers

    private func makeProduct(
        name: String = "GU Gel",
        type: ProductType = .gel,
        calories: Int = 100
    ) -> NutritionProduct {
        NutritionProduct(
            id: UUID(),
            name: name,
            type: type,
            caloriesPerServing: calories,
            carbsGramsPerServing: 25,
            sodiumMgPerServing: 50,
            caffeinated: false
        )
    }

    private func makeEntry(
        product: NutritionProduct,
        timingMinutes: Int,
        quantity: Int = 1
    ) -> NutritionEntry {
        NutritionEntry(
            id: UUID(),
            product: product,
            timingMinutes: timingMinutes,
            quantity: quantity,
            notes: nil
        )
    }

    private func makePlan(entries: [NutritionEntry]) -> NutritionPlan {
        NutritionPlan(
            id: UUID(),
            raceId: UUID(),
            caloriesPerHour: 250,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            entries: entries,
            gutTrainingSessionIds: []
        )
    }

    // MARK: - Gut Training Schedule

    @Test("buildGutTrainingSchedule maps entries correctly")
    func gutTrainingMapsEntries() {
        let gel = makeProduct(name: "GU Gel", type: .gel)
        let drink = makeProduct(name: "Tailwind", type: .drink)
        let salt = makeProduct(name: "Salt Tabs", type: .salt)

        let entries = [
            makeEntry(product: gel, timingMinutes: 30, quantity: 1),
            makeEntry(product: drink, timingMinutes: 20, quantity: 1),
            makeEntry(product: salt, timingMinutes: 45, quantity: 2),
        ]
        let plan = makePlan(entries: entries)
        let reminders = NutritionReminderScheduler.buildGutTrainingSchedule(from: plan)

        #expect(reminders.count == 3)

        // Sorted by trigger time: 20min, 30min, 45min
        #expect(reminders[0].triggerTimeSeconds == 1200)
        #expect(reminders[0].type == .hydration)
        #expect(reminders[0].message == "Take Tailwind")

        #expect(reminders[1].triggerTimeSeconds == 1800)
        #expect(reminders[1].type == .fuel)
        #expect(reminders[1].message == "Take GU Gel")

        #expect(reminders[2].triggerTimeSeconds == 2700)
        #expect(reminders[2].type == .electrolyte)
        #expect(reminders[2].message == "Take 2x Salt Tabs")
    }

    @Test("buildGutTrainingSchedule with empty entries returns empty")
    func gutTrainingEmptyEntries() {
        let plan = makePlan(entries: [])
        let reminders = NutritionReminderScheduler.buildGutTrainingSchedule(from: plan)

        #expect(reminders.isEmpty)
    }

    // MARK: - Default Schedule

    @Test("buildDefaultSchedule generates correct hydration intervals")
    func defaultHydrationIntervals() {
        let reminders = NutritionReminderScheduler.buildDefaultSchedule(maxDurationSeconds: 3600)
        let hydration = reminders.filter { $0.type == .hydration }

        // 20, 40, 60 min = 1200, 2400, 3600 seconds
        #expect(hydration.count == 3)
        #expect(hydration[0].triggerTimeSeconds == 1200)
        #expect(hydration[1].triggerTimeSeconds == 2400)
        #expect(hydration[2].triggerTimeSeconds == 3600)
    }

    @Test("buildDefaultSchedule generates correct fuel intervals")
    func defaultFuelIntervals() {
        let reminders = NutritionReminderScheduler.buildDefaultSchedule(maxDurationSeconds: 5400)
        let fuel = reminders.filter { $0.type == .fuel }

        // 45, 90 min = 2700, 5400 seconds
        #expect(fuel.count == 2)
        #expect(fuel[0].triggerTimeSeconds == 2700)
        #expect(fuel[1].triggerTimeSeconds == 5400)
    }

    @Test("buildDefaultSchedule respects max duration")
    func defaultRespectsMaxDuration() {
        let reminders = NutritionReminderScheduler.buildDefaultSchedule(maxDurationSeconds: 1000)

        // 1000s < 1200s (first hydration) and < 2700s (first fuel)
        #expect(reminders.isEmpty)
    }

    // MARK: - Next Due Reminder

    @Test("nextDueReminder finds first undismissed due reminder")
    func nextDueFindsFirst() {
        let reminders = [
            NutritionReminder(triggerTimeSeconds: 600, message: "A", type: .hydration),
            NutritionReminder(triggerTimeSeconds: 1200, message: "B", type: .fuel),
            NutritionReminder(triggerTimeSeconds: 1800, message: "C", type: .hydration),
        ]

        let result = NutritionReminderScheduler.nextDueReminder(in: reminders, at: 1500)

        #expect(result != nil)
        #expect(result?.message == "A")
    }

    @Test("nextDueReminder skips dismissed reminders")
    func nextDueSkipsDismissed() {
        let reminders = [
            NutritionReminder(triggerTimeSeconds: 600, message: "A", type: .hydration, isDismissed: true),
            NutritionReminder(triggerTimeSeconds: 1200, message: "B", type: .fuel),
            NutritionReminder(triggerTimeSeconds: 1800, message: "C", type: .hydration),
        ]

        let result = NutritionReminderScheduler.nextDueReminder(in: reminders, at: 1500)

        #expect(result != nil)
        #expect(result?.message == "B")
    }

    @Test("nextDueReminder returns nil when none are due")
    func nextDueNoneDue() {
        let reminders = [
            NutritionReminder(triggerTimeSeconds: 1200, message: "A", type: .hydration),
            NutritionReminder(triggerTimeSeconds: 1800, message: "B", type: .fuel),
        ]

        let result = NutritionReminderScheduler.nextDueReminder(in: reminders, at: 600)

        #expect(result == nil)
    }

    @Test("nextDueReminder returns nil when all are dismissed")
    func nextDueAllDismissed() {
        let reminders = [
            NutritionReminder(triggerTimeSeconds: 600, message: "A", type: .hydration, isDismissed: true),
            NutritionReminder(triggerTimeSeconds: 1200, message: "B", type: .fuel, isDismissed: true),
        ]

        let result = NutritionReminderScheduler.nextDueReminder(in: reminders, at: 1500)

        #expect(result == nil)
    }
}
