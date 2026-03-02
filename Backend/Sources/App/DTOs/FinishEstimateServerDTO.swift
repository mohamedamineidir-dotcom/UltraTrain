import Vapor

struct FinishEstimateUpsertRequest: Content, Validatable {
    let estimateId: String
    let raceId: String
    let expectedTime: Double
    let confidencePercent: Double
    let estimateJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?

    static func validations(_ validations: inout Validations) {
        validations.add("estimateId", as: String.self, is: !.empty)
        validations.add("raceId", as: String.self, is: !.empty)
        validations.add("expectedTime", as: Double.self, is: .range(0...604800))
        validations.add("confidencePercent", as: Double.self, is: .range(0...100))
        validations.add("estimateJson", as: String.self, is: !.empty)
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct FinishEstimateResponse: Content {
    let id: String
    let estimateId: String
    let raceId: String
    let expectedTime: Double
    let confidencePercent: Double
    let estimateJson: String
    let createdAt: String?
    let updatedAt: String?

    init(from model: FinishEstimateModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.estimateId = model.estimateId
        self.raceId = model.raceId
        self.expectedTime = model.expectedTime
        self.confidencePercent = model.confidencePercent
        self.estimateJson = model.estimateJSON
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}
