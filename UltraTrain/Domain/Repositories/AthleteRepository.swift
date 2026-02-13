import Foundation

protocol AthleteRepository: Sendable {
    func getAthlete() async throws -> Athlete?
    func saveAthlete(_ athlete: Athlete) async throws
    func updateAthlete(_ athlete: Athlete) async throws
}
