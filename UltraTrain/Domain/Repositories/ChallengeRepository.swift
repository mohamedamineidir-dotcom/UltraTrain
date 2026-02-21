import Foundation

protocol ChallengeRepository: Sendable {
    func getEnrollments() async throws -> [ChallengeEnrollment]
    func getActiveEnrollments() async throws -> [ChallengeEnrollment]
    func saveEnrollment(_ enrollment: ChallengeEnrollment) async throws
    func updateEnrollment(_ enrollment: ChallengeEnrollment) async throws
    func deleteEnrollment(id: UUID) async throws
}
