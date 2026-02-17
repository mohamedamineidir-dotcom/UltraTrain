import Foundation

protocol RunImportUseCase: Sendable {
    func importFromGPX(data: Data, athleteId: UUID) async throws -> CompletedRun
}
