import Foundation

protocol RaceReflectionRepository: Sendable {
    func getReflection(for raceId: UUID) async throws -> RaceReflection?
    func saveReflection(_ reflection: RaceReflection) async throws
}
