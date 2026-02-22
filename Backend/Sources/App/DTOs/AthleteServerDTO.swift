import Vapor

struct AthleteResponse: Content {
    let id: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let weightKg: Double
    let heightCm: Double
    let restingHeartRate: Int
    let maxHeartRate: Int
    let experienceLevel: String
    let weeklyVolumeKm: Double
    let longestRunKm: Double
    let updatedAt: String?

    init(from model: AthleteModel) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        self.firstName = model.firstName
        self.lastName = model.lastName
        self.dateOfBirth = formatter.string(from: model.dateOfBirth)
        self.weightKg = model.weightKg
        self.heightCm = model.heightCm
        self.restingHeartRate = model.restingHeartRate
        self.maxHeartRate = model.maxHeartRate
        self.experienceLevel = model.experienceLevel
        self.weeklyVolumeKm = model.weeklyVolumeKm
        self.longestRunKm = model.longestRunKm
        self.updatedAt = model.updatedAt.map { formatter.string(from: $0) }
    }
}

struct AthleteUpdateRequest: Content, Validatable {
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let weightKg: Double
    let heightCm: Double
    let restingHeartRate: Int
    let maxHeartRate: Int
    let experienceLevel: String
    let weeklyVolumeKm: Double
    let longestRunKm: Double

    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("weightKg", as: Double.self, is: .range(20...300))
        validations.add("heightCm", as: Double.self, is: .range(100...250))
        validations.add("restingHeartRate", as: Int.self, is: .range(30...120))
        validations.add("maxHeartRate", as: Int.self, is: .range(100...230))
    }
}
