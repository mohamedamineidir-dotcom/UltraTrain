import Foundation

enum NutritionReminderScheduler {

    // MARK: - Gut Training Schedule

    static func buildGutTrainingSchedule(from plan: NutritionPlan) -> [NutritionReminder] {
        plan.entries
            .map { entry in
                let triggerTime = TimeInterval(entry.timingMinutes) * 60
                let quantityLabel = entry.quantity > 1 ? "\(entry.quantity)x " : ""
                let message = "Take \(quantityLabel)\(entry.product.name)"
                let type = reminderType(for: entry.product.type)

                return NutritionReminder(
                    triggerTimeSeconds: triggerTime,
                    message: message,
                    type: type
                )
            }
            .sorted { $0.triggerTimeSeconds < $1.triggerTimeSeconds }
    }

    // MARK: - Default Schedule

    static func buildDefaultSchedule(
        maxDurationSeconds: TimeInterval = AppConfiguration.NutritionReminders.maxScheduleDuration
    ) -> [NutritionReminder] {
        var reminders: [NutritionReminder] = []

        let hydrationInterval = AppConfiguration.NutritionReminders.hydrationIntervalSeconds
        var time = hydrationInterval
        while time <= maxDurationSeconds {
            reminders.append(NutritionReminder(
                triggerTimeSeconds: time,
                message: "Time to hydrate — drink water or electrolytes",
                type: .hydration
            ))
            time += hydrationInterval
        }

        let fuelInterval = AppConfiguration.NutritionReminders.fuelIntervalSeconds
        time = fuelInterval
        while time <= maxDurationSeconds {
            reminders.append(NutritionReminder(
                triggerTimeSeconds: time,
                message: "Time to fuel — take a gel or snack",
                type: .fuel
            ))
            time += fuelInterval
        }

        return reminders.sorted { $0.triggerTimeSeconds < $1.triggerTimeSeconds }
    }

    // MARK: - Next Due Reminder

    static func nextDueReminder(
        in reminders: [NutritionReminder],
        at elapsedTime: TimeInterval
    ) -> NutritionReminder? {
        reminders
            .filter { !$0.isDismissed && $0.triggerTimeSeconds <= elapsedTime }
            .sorted { $0.triggerTimeSeconds < $1.triggerTimeSeconds }
            .first
    }

    // MARK: - Private

    private static func reminderType(for productType: ProductType) -> NutritionReminderType {
        switch productType {
        case .drink:
            return .hydration
        case .salt:
            return .electrolyte
        case .gel, .bar, .chew, .realFood:
            return .fuel
        }
    }
}
