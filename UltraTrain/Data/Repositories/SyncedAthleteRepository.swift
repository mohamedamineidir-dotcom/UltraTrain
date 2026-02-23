import Foundation
import os

final class SyncedAthleteRepository: AthleteRepository, @unchecked Sendable {
    private let local: LocalAthleteRepository
    private let remote: RemoteAthleteDataSource
    private let authService: any AuthServiceProtocol

    init(
        local: LocalAthleteRepository,
        remote: RemoteAthleteDataSource,
        authService: any AuthServiceProtocol
    ) {
        self.local = local
        self.remote = remote
        self.authService = authService
    }

    func getAthlete() async throws -> Athlete? {
        if let localAthlete = try await local.getAthlete() {
            // Background refresh from server
            if authService.isAuthenticated() {
                Task {
                    do {
                        let dto = try await self.remote.fetchAthlete()
                        if let athlete = AthleteMapper.toDomain(dto) {
                            try await self.local.updateAthlete(athlete)
                        }
                    } catch {
                        Logger.network.warning("Background athlete fetch failed: \(error)")
                    }
                }
            }
            return localAthlete
        }

        // No local athlete — try to restore from server
        return await restoreFromRemoteIfNeeded()
    }

    private func restoreFromRemoteIfNeeded() async -> Athlete? {
        guard authService.isAuthenticated() else { return nil }
        do {
            let dto = try await remote.fetchAthlete()
            guard let athlete = AthleteMapper.toDomain(dto) else { return nil }
            try await local.saveAthlete(athlete)
            Logger.network.info("Restored athlete profile from server")
            return athlete
        } catch {
            Logger.network.info("No remote athlete to restore: \(error)")
            return nil
        }
    }

    func saveAthlete(_ athlete: Athlete) async throws {
        try await local.saveAthlete(athlete)

        guard authService.isAuthenticated() else { return }
        Task {
            do {
                let dto = AthleteMapper.toDTO(athlete)
                _ = try await self.remote.updateAthlete(dto)
            } catch {
                Logger.network.warning("Athlete remote sync failed: \(error)")
            }
        }
    }

    func updateAthlete(_ athlete: Athlete) async throws {
        try await local.updateAthlete(athlete)

        guard authService.isAuthenticated() else { return }
        Task {
            do {
                let dto = AthleteMapper.toDTO(athlete)
                _ = try await self.remote.updateAthlete(dto)
            } catch {
                Logger.network.warning("Athlete remote update failed: \(error)")
            }
        }
    }
}
