import Vapor

struct NutritionUpsertRequest: Content, Validatable {
    let nutritionPlanId: String
    let raceId: String
    let caloriesPerHour: Int
    let nutritionJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?

    static func validations(_ validations: inout Validations) {
        validations.add("nutritionPlanId", as: String.self, is: !.empty)
        validations.add("raceId", as: String.self, is: !.empty)
        validations.add("caloriesPerHour", as: Int.self, is: .range(0...5000))
        validations.add("nutritionJson", as: String.self, is: !.empty)
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct NutritionResponse: Content {
    let id: String
    let nutritionPlanId: String
    let raceId: String
    let caloriesPerHour: Int
    let nutritionJson: String
    let createdAt: String?
    let updatedAt: String?

    init(from model: NutritionPlanModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.nutritionPlanId = model.nutritionPlanId
        self.raceId = model.raceId
        self.caloriesPerHour = model.caloriesPerHour
        self.nutritionJson = model.nutritionJSON
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}
