import Vapor

struct TrainingPlanUploadRequest: Content, Validatable {
    let planId: String
    let targetRaceName: String
    let targetRaceDate: String
    let totalWeeks: Int
    let planJson: String
    let idempotencyKey: String

    static func validations(_ validations: inout Validations) {
        validations.add("planId", as: String.self, is: !.empty)
        validations.add("targetRaceName", as: String.self, is: !.empty)
        validations.add("totalWeeks", as: Int.self, is: .range(1...52))
        validations.add("planJson", as: String.self, is: !.empty)
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct TrainingPlanResponse: Content {
    let id: String
    let targetRaceName: String
    let targetRaceDate: String
    let totalWeeks: Int
    let planJson: String
    let createdAt: String?
    let updatedAt: String?

    init(from model: TrainingPlanModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.targetRaceName = model.targetRaceName
        self.targetRaceDate = formatter.string(from: model.targetRaceDate)
        self.totalWeeks = model.totalWeeks
        self.planJson = model.planJSON
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}
