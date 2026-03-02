import Vapor

struct FitnessSnapshotUpsertRequest: Content, Validatable {
    let snapshotId: String
    let date: String
    let fitness: Double
    let fatigue: Double
    let form: Double
    let fitnessJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?

    static func validations(_ validations: inout Validations) {
        validations.add("snapshotId", as: String.self, is: !.empty)
        validations.add("fitnessJson", as: String.self, is: !.empty)
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct FitnessSnapshotResponse: Content {
    let id: String
    let snapshotId: String
    let date: String
    let fitness: Double
    let fatigue: Double
    let form: Double
    let fitnessJson: String
    let createdAt: String?
    let updatedAt: String?

    init(from model: FitnessSnapshotModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.snapshotId = model.snapshotId
        self.date = formatter.string(from: model.date)
        self.fitness = model.fitness
        self.fatigue = model.fatigue
        self.form = model.form
        self.fitnessJson = model.fitnessJSON
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}
