import Foundation
import os

final class RunRestoreService: @unchecked Sendable {
    private let remote: RemoteRunDataSource
    private let authService: any AuthServiceProtocol
    private let athleteRepository: any AthleteRepository

    init(
        remote: RemoteRunDataSource,
        authService: any AuthServiceProtocol,
        athleteRepository: any AthleteRepository
    ) {
        self.remote = remote
        self.authService = authService
        self.athleteRepository = athleteRepository
    }

    func restoreRuns() async -> [CompletedRun] {
        guard authService.isAuthenticated() else { return [] }

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                Logger.network.info("RunRestoreService: no athlete for run restore")
                return []
            }

            let dtos = try await remote.fetchRuns()
            let runs = dtos.compactMap { RunMapper.toDomain($0, athleteId: athlete.id) }
            Logger.network.info("RunRestoreService: restored \(runs.count) runs from server")
            return runs
        } catch {
            Logger.network.info("RunRestoreService: no remote runs to restore: \(error)")
            return []
        }
    }
}
