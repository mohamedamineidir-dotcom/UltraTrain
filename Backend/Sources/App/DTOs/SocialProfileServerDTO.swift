import Vapor

struct SocialProfileUpdateRequest: Content, Validatable {
    let displayName: String
    let bio: String?
    let isPublicProfile: Bool

    static func validations(_ validations: inout Validations) {
        validations.add("displayName", as: String.self, is: !.empty && .count(...100))
    }
}

struct SocialProfileResponse: Content {
    let id: String
    let displayName: String
    let bio: String?
    let experienceLevel: String
    let isPublicProfile: Bool
    let totalDistanceKm: Double
    let totalElevationGainM: Double
    let totalRuns: Int
    let joinedDate: String

    init(from athlete: AthleteModel, userId: UUID, totalDistanceKm: Double, totalElevationGainM: Double, totalRuns: Int, joinedDate: Date) {
        let formatter = ISO8601DateFormatter()
        self.id = userId.uuidString
        self.displayName = athlete.displayName.isEmpty ? "\(athlete.firstName) \(athlete.lastName)" : athlete.displayName
        self.bio = athlete.bio
        self.experienceLevel = athlete.experienceLevel
        self.isPublicProfile = athlete.isPublicProfile
        self.totalDistanceKm = totalDistanceKm
        self.totalElevationGainM = totalElevationGainM
        self.totalRuns = totalRuns
        self.joinedDate = formatter.string(from: joinedDate)
    }
}
