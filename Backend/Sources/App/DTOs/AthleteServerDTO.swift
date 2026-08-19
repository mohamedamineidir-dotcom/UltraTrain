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
    let itraIndex: Double?
    let itraIndexUpdatedAt: String?
    let previousItraIndex: Double?
    let previousItraIndexUpdatedAt: String?
    let utmbIndex: Double?
    let utmbIndexUpdatedAt: String?
    let previousUtmbIndex: Double?
    let previousUtmbIndexUpdatedAt: String?
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
        self.itraIndex = model.itraIndex
        self.itraIndexUpdatedAt = model.itraIndexUpdatedAt.map { formatter.string(from: $0) }
        self.previousItraIndex = model.previousItraIndex
        self.previousItraIndexUpdatedAt = model.previousItraIndexUpdatedAt.map { formatter.string(from: $0) }
        self.utmbIndex = model.utmbIndex
        self.utmbIndexUpdatedAt = model.utmbIndexUpdatedAt.map { formatter.string(from: $0) }
        self.previousUtmbIndex = model.previousUtmbIndex
        self.previousUtmbIndexUpdatedAt = model.previousUtmbIndexUpdatedAt.map { formatter.string(from: $0) }
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
    var itraIndex: Double?
    var itraIndexUpdatedAt: String?
    var previousItraIndex: Double?
    var previousItraIndexUpdatedAt: String?
    var utmbIndex: Double?
    var utmbIndexUpdatedAt: String?
    var previousUtmbIndex: Double?
    var previousUtmbIndexUpdatedAt: String?

    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("weightKg", as: Double.self, is: .range(20...300))
        validations.add("heightCm", as: Double.self, is: .range(100...250))
        validations.add("restingHeartRate", as: Int.self, is: .range(30...120))
        validations.add("maxHeartRate", as: Int.self, is: .range(100...230))
        validations.add("itraIndex", as: Double.self, is: .range(0...1000), required: false)
        validations.add("utmbIndex", as: Double.self, is: .range(0...1000), required: false)
    }
}
