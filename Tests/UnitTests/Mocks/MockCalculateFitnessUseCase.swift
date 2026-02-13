import Foundation
@testable import UltraTrain

final class MockCalculateFitnessUseCase: CalculateFitnessUseCase, @unchecked Sendable {
    var resultSnapshot: FitnessSnapshot?
    var shouldThrow = false

    func execute(runs: [CompletedRun], asOf date: Date) async throws -> FitnessSnapshot {
        if shouldThrow { throw DomainError.insufficientData(reason: "Mock error") }
        return resultSnapshot ?? FitnessSnapshot(
            id: UUID(),
            date: date,
            fitness: 0,
            fatigue: 0,
            form: 0,
            weeklyVolumeKm: 0,
            weeklyElevationGainM: 0,
            weeklyDuration: 0,
            acuteToChronicRatio: 0
        )
    }
}
