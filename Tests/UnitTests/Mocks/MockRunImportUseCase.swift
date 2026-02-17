import Foundation
@testable import UltraTrain

final class MockRunImportUseCase: RunImportUseCase, @unchecked Sendable {
    var importCalled = false
    var shouldThrow = false
    var importedRun: CompletedRun?

    func importFromGPX(data: Data, athleteId: UUID) async throws -> CompletedRun {
        importCalled = true
        if shouldThrow { throw DomainError.importFailed(reason: "Mock error") }

        let run = CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date(),
            distanceKm: 10.0,
            elevationGainM: 500,
            elevationLossM: 480,
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            notes: "Imported: Mock Run",
            pausedDuration: 0
        )
        importedRun = run
        return run
    }
}
