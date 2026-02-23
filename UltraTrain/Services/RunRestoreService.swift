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

            var allDTOs: [RunResponseDTO] = []
            var cursor: String? = nil
            repeat {
                let page = try await remote.fetchRuns(cursor: cursor, limit: 100)
                allDTOs.append(contentsOf: page.items)
                cursor = page.nextCursor
            } while cursor != nil
            let runs = allDTOs.compactMap { RunMapper.toDomain($0, athleteId: athlete.id) }
            Logger.network.info("RunRestoreService: restored \(runs.count) runs from server")
            return runs
        } catch {
            Logger.network.info("RunRestoreService: no remote runs to restore: \(error)")
            return []
        }
    }
}
