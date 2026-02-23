import Vapor

struct RaceUploadRequest: Content, Validatable {
    let raceId: String
    let name: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let priority: String
    let raceJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?

    static func validations(_ validations: inout Validations) {
        validations.add("raceId", as: String.self, is: !.empty)
        validations.add("name", as: String.self, is: !.empty)
        validations.add("distanceKm", as: Double.self, is: .range(0.1...1000))
        validations.add("elevationGainM", as: Double.self, is: .range(0...50000))
        validations.add("priority", as: String.self, is: .in("aRace", "bRace", "cRace"))
        validations.add("raceJson", as: String.self, is: !.empty)
        validations.add("idempotencyKey", as: String.self, is: !.empty)
    }
}

struct RaceResponse: Content {
    let id: String
    let raceId: String
    let name: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let priority: String
    let raceJson: String
    let createdAt: String?
    let updatedAt: String?

    init(from model: RaceModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.raceId = model.raceId
        self.name = model.name
        self.date = formatter.string(from: model.date)
        self.distanceKm = model.distanceKm
        self.elevationGainM = model.elevationGainM
        self.priority = model.priority
        self.raceJson = model.raceJSON
        self.createdAt = model.createdAt.map { formatter.string(from: $0) }
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}
