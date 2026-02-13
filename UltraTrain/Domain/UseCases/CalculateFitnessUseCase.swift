import Foundation

protocol CalculateFitnessUseCase: Sendable {
    func execute(
        runs: [CompletedRun],
        asOf date: Date
    ) async throws -> FitnessSnapshot
}
