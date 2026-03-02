import Foundation
import os

@Observable
@MainActor
final class NutritionTimerViewModel {

    // MARK: - State

    var isRunning = false
    var elapsedSeconds: TimeInterval = 0
    var nutritionPlan: ClipNutritionPlanData?
    var reminders: [TimerReminder] = []
    var activeReminder: TimerReminder?
    var showFullAppPrompt = false
    var error: String?

    private var timer: Timer?
    private let logger = Logger(subsystem: "com.ultratrain.app.Clip", category: "NutritionTimer")

    struct TimerReminder: Identifiable, Equatable {
        let id: UUID
        let triggerTimeSeconds: TimeInterval
        let message: String
        let type: ReminderType
        var isDismissed = false
        var isTriggered = false

        enum ReminderType: String {
            case hydration
            case fuel
            case electrolyte

            var icon: String {
                switch self {
                case .hydration: "drop.fill"
                case .fuel: "bolt.fill"
                case .electrolyte: "sparkles"
                }
            }
        }
    }

    // MARK: - Load

    func load(raceId: String?) {
        guard let raceId else {
            error = "No race specified"
            showFullAppPrompt = true
            return
        }
        if let plan = ClipNutritionDataReader.readNutritionPlan(raceId: raceId) {
            nutritionPlan = plan
            buildReminderSchedule(from: plan)
        } else {
            error = "No nutrition plan found. Install UltraTrain to create one."
            showFullAppPrompt = true
        }
    }

    // MARK: - Timer

    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        logger.info("Nutrition timer started")
    }

    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        logger.info("Nutrition timer stopped")
    }

    func resetTimer() {
        stopTimer()
        elapsedSeconds = 0
        for i in reminders.indices {
            reminders[i].isDismissed = false
            reminders[i].isTriggered = false
        }
        activeReminder = nil
        updateNextReminder()
    }

    func dismissReminder(_ reminder: TimerReminder) {
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx].isDismissed = true
        }
        activeReminder = nil
        updateNextReminder()
    }

    // MARK: - Private

    private func tick() {
        elapsedSeconds += 1
        checkReminders()
    }

    private func buildReminderSchedule(from plan: ClipNutritionPlanData) {
        let maxDuration: TimeInterval = 36 * 3600
        var result: [TimerReminder] = []

        if plan.hydrationIntervalSeconds > 0 {
            var t = plan.hydrationIntervalSeconds
            while t <= maxDuration {
                result.append(TimerReminder(
                    id: UUID(), triggerTimeSeconds: t,
                    message: "Hydrate — \(plan.hydrationMlPerHour) ml/hr",
                    type: .hydration
                ))
                t += plan.hydrationIntervalSeconds
            }
        }

        if plan.fuelIntervalSeconds > 0 {
            var t = plan.fuelIntervalSeconds
            while t <= maxDuration {
                result.append(TimerReminder(
                    id: UUID(), triggerTimeSeconds: t,
                    message: "Take fuel — \(plan.caloriesPerHour) cal/hr",
                    type: .fuel
                ))
                t += plan.fuelIntervalSeconds
            }
        }

        if plan.electrolyteIntervalSeconds > 0 {
            var t = plan.electrolyteIntervalSeconds
            while t <= maxDuration {
                result.append(TimerReminder(
                    id: UUID(), triggerTimeSeconds: t,
                    message: "Electrolytes — \(plan.sodiumMgPerHour) mg Na/hr",
                    type: .electrolyte
                ))
                t += plan.electrolyteIntervalSeconds
            }
        }

        reminders = result.sorted { $0.triggerTimeSeconds < $1.triggerTimeSeconds }
        updateNextReminder()
    }

    private func checkReminders() {
        for i in reminders.indices {
            guard !reminders[i].isTriggered, !reminders[i].isDismissed else { continue }
            if elapsedSeconds >= reminders[i].triggerTimeSeconds {
                reminders[i].isTriggered = true
                activeReminder = reminders[i]
            }
        }
    }

    private func updateNextReminder() {
        activeReminder = reminders.first { !$0.isDismissed && !$0.isTriggered && $0.triggerTimeSeconds > elapsedSeconds }
    }
}
