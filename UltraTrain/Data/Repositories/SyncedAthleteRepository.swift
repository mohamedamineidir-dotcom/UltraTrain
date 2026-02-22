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
        let localAthlete = try await local.getAthlete()

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
