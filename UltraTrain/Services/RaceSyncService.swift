import Foundation
import os

final class RaceSyncService: @unchecked Sendable {
    private let remote: RemoteRaceDataSource
    private let authService: any AuthServiceProtocol

    init(remote: RemoteRaceDataSource, authService: any AuthServiceProtocol) {
        self.remote = remote
        self.authService = authService
    }

    func syncRace(_ race: Race) async {
        guard authService.isAuthenticated() else { return }
        guard let dto = RaceRemoteMapper.toUploadDTO(race) else {
            Logger.network.error("RaceSyncService: failed to map race to DTO")
            return
        }
        do {
            _ = try await remote.upsertRace(dto)
            Logger.network.info("RaceSyncService: synced race \(race.id)")
        } catch {
            Logger.network.warning("RaceSyncService: sync failed: \(error)")
        }
    }

    func deleteRace(id: UUID) async {
        guard authService.isAuthenticated() else { return }
        do {
            try await remote.deleteRace(id: id.uuidString)
            Logger.network.info("RaceSyncService: deleted race \(id) from server")
        } catch {
            Logger.network.warning("RaceSyncService: remote delete failed: \(error)")
        }
    }

    func restoreRaces() async -> [Race] {
        guard authService.isAuthenticated() else { return [] }
        do {
            let responses = try await remote.fetchRaces()
            let races = responses.compactMap { RaceRemoteMapper.toDomain(from: $0) }
            Logger.network.info("RaceSyncService: restored \(races.count) races from server")
            return races
        } catch {
            Logger.network.info("RaceSyncService: no remote races to restore: \(error)")
            return []
        }
    }
}
