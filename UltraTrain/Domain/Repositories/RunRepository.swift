import Foundation

protocol RunRepository: Sendable {
    func getRuns(for athleteId: UUID) async throws -> [CompletedRun]
    func getRun(id: UUID) async throws -> CompletedRun?
    func saveRun(_ run: CompletedRun) async throws
    func deleteRun(id: UUID) async throws
    func getRecentRuns(limit: Int) async throws -> [CompletedRun]
    func updateRun(_ run: CompletedRun) async throws
}
