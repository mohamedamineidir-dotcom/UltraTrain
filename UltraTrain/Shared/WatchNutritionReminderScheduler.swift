import Foundation

enum WatchNutritionReminderScheduler {

    static func buildDefaultSchedule(
        hydrationInterval: TimeInterval = WatchConfiguration.NutritionReminders.hydrationIntervalSeconds,
        fuelInterval: TimeInterval = WatchConfiguration.NutritionReminders.fuelIntervalSeconds,
        maxDuration: TimeInterval = WatchConfiguration.NutritionReminders.maxScheduleDuration
    ) -> [WatchNutritionReminder] {
        var reminders: [WatchNutritionReminder] = []

        var time = hydrationInterval
        while time <= maxDuration {
            reminders.append(WatchNutritionReminder(
                triggerTimeSeconds: time,
                message: "Time to hydrate — drink water or electrolytes",
                type: .hydration
            ))
            time += hydrationInterval
        }

        time = fuelInterval
        while time <= maxDuration {
            reminders.append(WatchNutritionReminder(
                triggerTimeSeconds: time,
                message: "Time to fuel — take a gel or snack",
                type: .fuel
            ))
            time += fuelInterval
        }

        return reminders.sorted { $0.triggerTimeSeconds < $1.triggerTimeSeconds }
    }

    static func nextDueReminder(
        in reminders: [WatchNutritionReminder],
        at elapsedTime: TimeInterval
    ) -> WatchNutritionReminder? {
        reminders
            .filter { !$0.isDismissed && $0.triggerTimeSeconds <= elapsedTime }
            .sorted { $0.triggerTimeSeconds < $1.triggerTimeSeconds }
            .first
    }
}
