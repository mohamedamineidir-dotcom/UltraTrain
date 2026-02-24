import Vapor

struct CreateChallengeRequest: Content, Validatable {
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

struct UpdateProgressRequest: Content, Validatable {
    let value: Double

    static func validations(_ validations: inout Validations) {
        validations.add("value", as: Double.self, is: .range(0...1000000))
    }
}

struct ChallengeParticipantResponse: Content {
    let id: String
    let displayName: String
    let currentValue: Double
    let joinedDate: String

    init(from model: ChallengeParticipantModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.$user.id.uuidString
        self.displayName = model.displayName
        self.currentValue = model.currentValue
        self.joinedDate = formatter.string(from: model.joinedDate)
    }
}

struct GroupChallengeResponse: Content {
    let id: String
    let creatorProfileId: String
    let creatorDisplayName: String
    let name: String
    let descriptionText: String
    let type: String
    let targetValue: Double
    let startDate: String
    let endDate: String
    let status: String
    let participants: [ChallengeParticipantResponse]

    init(from model: GroupChallengeModel, creatorDisplayName: String, participants: [ChallengeParticipantModel]) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.creatorProfileId = model.$creator.id.uuidString
        self.creatorDisplayName = creatorDisplayName
        self.name = model.name
        self.descriptionText = model.descriptionText
        self.type = model.type
        self.targetValue = model.targetValue
        self.startDate = formatter.string(from: model.startDate)
        self.endDate = formatter.string(from: model.endDate)
        self.status = model.status
        self.participants = participants.map { ChallengeParticipantResponse(from: $0) }
    }
}
