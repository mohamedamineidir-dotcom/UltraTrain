import Foundation

struct NutritionIntakeEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var reminderType: NutritionReminderType
    var status: NutritionIntakeStatus
    var elapsedTimeSeconds: TimeInterval
    var message: String
    var productId: UUID?
    var productName: String?
    var caloriesConsumed: Int?
    var carbsGramsConsumed: Double?
    var sodiumMgConsumed: Int?
    var isManualEntry: Bool

    init(
        id: UUID = UUID(),
        reminderType: NutritionReminderType,
        status: NutritionIntakeStatus,
        elapsedTimeSeconds: TimeInterval,
        message: String,
        productId: UUID? = nil,
        productName: String? = nil,
        caloriesConsumed: Int? = nil,
        carbsGramsConsumed: Double? = nil,
        sodiumMgConsumed: Int? = nil,
        isManualEntry: Bool = false
    ) {
        self.id = id
        self.reminderType = reminderType
        self.status = status
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.message = message
        self.productId = productId
        self.productName = productName
        self.caloriesConsumed = caloriesConsumed
        self.carbsGramsConsumed = carbsGramsConsumed
        self.sodiumMgConsumed = sodiumMgConsumed
        self.isManualEntry = isManualEntry
    }
}
