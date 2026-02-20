import Foundation

protocol RacePrepChecklistRepository: Sendable {
    func getChecklist(for raceId: UUID) async throws -> RacePrepChecklist?
    func saveChecklist(_ checklist: RacePrepChecklist) async throws
    func deleteChecklist(for raceId: UUID) async throws
}
