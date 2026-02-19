import Foundation

struct NutritionIntakeSummary: Equatable, Sendable {
    var entries: [NutritionIntakeEntry]

    var takenCount: Int { entries.filter { $0.status == .taken }.count }
    var skippedCount: Int { entries.filter { $0.status == .skipped }.count }
    var pendingCount: Int { entries.filter { $0.status == .pending }.count }

    var hydrationTakenCount: Int {
        entries.filter { $0.reminderType == .hydration && $0.status == .taken }.count
    }

    var fuelTakenCount: Int {
        entries.filter { $0.reminderType == .fuel && $0.status == .taken }.count
    }

    var electrolyteTakenCount: Int {
        entries.filter { $0.reminderType == .electrolyte && $0.status == .taken }.count
    }
}
