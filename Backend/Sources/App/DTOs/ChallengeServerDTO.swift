import Vapor

struct ChallengeCreateRequest: Content, Validatable {
    let name: String
    let descriptionText: String
    let type: String
    let targetValue: Double
    let startDate: String
    let endDate: String
    let idempotencyKey: String

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...100))
        validations.add("descriptionText", as: String.self, is: !.empty)
        validations.add("type", as: String.self, is: .in("distance", "elevation", "consistency", "streak"))
        validations.add("targetValue", as: Double.self, is: .range(0.1...1000000))
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct ChallengeUpdateProgressRequest: Content, Validatable {
    let value: Double
    let idempotencyKey: String

    static func validations(_ validations: inout Validations) {
        validations.add("value", as: Double.self, is: .range(0...1000000))
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct ChallengeResponse: Content {
    let id: String
    let name: String
    let descriptionText: String
    let type: String
    let targetValue: Double
    let currentValue: Double
    let startDate: String
    let endDate: String
    let status: String
    let createdAt: String?
    let updatedAt: String?

    init(from model: ChallengeModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.name = model.name
        self.descriptionText = model.descriptionText
        self.type = model.type
        self.targetValue = model.targetValue
        self.currentValue = model.currentValue
        self.startDate = formatter.string(from: model.startDate)
        self.endDate = formatter.string(from: model.endDate)
        self.status = model.status
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}
