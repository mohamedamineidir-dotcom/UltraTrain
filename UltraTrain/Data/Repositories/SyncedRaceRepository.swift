import Foundation
import os

final class SyncedRaceRepository: RaceRepository, @unchecked Sendable {
    private let local: LocalRaceRepository
    private let syncService: RaceSyncService
    private let syncQueue: (any SyncQueueServiceProtocol)?
    private var hasAttemptedRestore = false

    init(
        local: LocalRaceRepository,
        syncService: RaceSyncService,
        syncQueue: (any SyncQueueServiceProtocol)? = nil
    ) {
        self.local = local
        self.syncService = syncService
        self.syncQueue = syncQueue
    }

    func getRaces() async throws -> [Race] {
        let localRaces = try await local.getRaces()
        if localRaces.isEmpty, let restored = await restoreIfNeeded() {
            return restored
        }
        return localRaces
    }

    func getRace(id: UUID) async throws -> Race? {
        try await local.getRace(id: id)
    }

    func saveRace(_ race: Race) async throws {
        try await local.saveRace(race)
        if let queue = syncQueue {
            try? await queue.enqueueOperation(.raceSync, entityId: race.id)
        } else {
            Task { await syncService.syncRace(race) }
        }
    }

    func updateRace(_ race: Race) async throws {
        try await local.updateRace(race)
        if let queue = syncQueue {
            try? await queue.enqueueOperation(.raceSync, entityId: race.id)
        } else {
            Task { await syncService.syncRace(race) }
        }
    }

    func deleteRace(id: UUID) async throws {
        try await local.deleteRace(id: id)
        if let queue = syncQueue {
            try? await queue.enqueueOperation(.raceDelete, entityId: id)
        } else {
            Task { await syncService.deleteRace(id: id) }
        }
    }

    private func restoreIfNeeded() async -> [Race]? {
        guard !hasAttemptedRestore else { return nil }
        hasAttemptedRestore = true
        let races = await syncService.restoreRaces()
        guard !races.isEmpty else { return nil }
        for race in races {
            try? await local.saveRace(race)
        }
        Logger.network.info("SyncedRaceRepository: saved \(races.count) restored races locally")
        return races
    }
}
