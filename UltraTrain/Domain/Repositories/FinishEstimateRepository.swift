import Foundation

protocol FinishEstimateRepository: Sendable {
    func getEstimate(for raceId: UUID) async throws -> FinishEstimate?
    func saveEstimate(_ estimate: FinishEstimate) async throws
}
