import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalRaceRepository Tests")
@MainActor
struct LocalRaceRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            RaceSwiftDataModel.self,
            CheckpointSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRace(
        id: UUID = UUID(),
        name: String = "UTMB",
        date: Date = Date(timeIntervalSince1970: 1_700_000_000),
        distanceKm: Double = 171,
        elevationGainM: Double = 10000,
        elevationLossM: Double = 10000,
        priority: RacePriority = .aRace,
        goalType: RaceGoal = .finish,
        checkpoints: [Checkpoint] = [],
        terrainDifficulty: TerrainDifficulty = .technical,
        actualFinishTime: TimeInterval? = nil,
        linkedRunId: UUID? = nil
    ) -> Race {
        Race(
            id: id,
            name: name,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            priority: priority,
            goalType: goalType,
            checkpoints: checkpoints,
            terrainDifficulty: terrainDifficulty,
            actualFinishTime: actualFinishTime,
            linkedRunId: linkedRunId
        )
    }

    private func makeCheckpoint(
        name: String = "Aid Station",
        distanceKm: Double = 30,
        elevationM: Double = 1500,
        hasAidStation: Bool = true
    ) -> Checkpoint {
        Checkpoint(
            id: UUID(),
            name: name,
            distanceFromStartKm: distanceKm,
            elevationM: elevationM,
            hasAidStation: hasAidStation
        )
    }

    // MARK: - Save & Fetch

    @Test("Save race and fetch by ID returns the saved race")
    func saveAndFetchById() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let race = makeRace()

        try await repo.saveRace(race)
        let fetched = try await repo.getRace(id: race.id)

        #expect(fetched != nil)
        #expect(fetched?.id == race.id)
        #expect(fetched?.name == "UTMB")
        #expect(fetched?.distanceKm == 171)
        #expect(fetched?.elevationGainM == 10000)
        #expect(fetched?.priority == .aRace)
        #expect(fetched?.terrainDifficulty == .technical)
        #expect(fetched?.goalType == .finish)
    }

    @Test("Fetch race with nonexistent ID returns nil")
    func fetchNonexistentRaceReturnsNil() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)

        let fetched = try await repo.getRace(id: UUID())
        #expect(fetched == nil)
    }

    // MARK: - Get All Races

    @Test("Get races returns all races sorted by date ascending")
    func getRacesSortedByDate() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)

        let laterDate = Date(timeIntervalSince1970: 2_000_000_000)
        let earlierDate = Date(timeIntervalSince1970: 1_000_000_000)
        let middleDate = Date(timeIntervalSince1970: 1_500_000_000)

        try await repo.saveRace(makeRace(name: "Later Race", date: laterDate))
        try await repo.saveRace(makeRace(name: "Earlier Race", date: earlierDate))
        try await repo.saveRace(makeRace(name: "Middle Race", date: middleDate))

        let races = try await repo.getRaces()

        #expect(races.count == 3)
        #expect(races[0].name == "Earlier Race")
        #expect(races[1].name == "Middle Race")
        #expect(races[2].name == "Later Race")
    }

    @Test("Get races when empty returns empty array")
    func getRacesEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)

        let races = try await repo.getRaces()
        #expect(races.isEmpty)
    }

    // MARK: - Update

    @Test("Update race modifies all updatable fields")
    func updateRaceModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let raceId = UUID()

        let original = makeRace(id: raceId, name: "UTMB", distanceKm: 171, priority: .aRace, goalType: .finish)
        try await repo.saveRace(original)

        let runId = UUID()
        let updated = makeRace(
            id: raceId,
            name: "UTMB 2025",
            date: Date(timeIntervalSince1970: 1_800_000_000),
            distanceKm: 172,
            elevationGainM: 10100,
            elevationLossM: 10100,
            priority: .bRace,
            goalType: .targetTime(36 * 3600),
            terrainDifficulty: .extreme,
            actualFinishTime: 38 * 3600,
            linkedRunId: runId
        )
        try await repo.updateRace(updated)

        let fetched = try await repo.getRace(id: raceId)
        #expect(fetched?.name == "UTMB 2025")
        #expect(fetched?.distanceKm == 172)
        #expect(fetched?.elevationGainM == 10100)
        #expect(fetched?.elevationLossM == 10100)
        #expect(fetched?.priority == .bRace)
        #expect(fetched?.goalType == .targetTime(TimeInterval(36 * 3600)))
        #expect(fetched?.terrainDifficulty == .extreme)
        #expect(fetched?.actualFinishTime == TimeInterval(38 * 3600))
        #expect(fetched?.linkedRunId == runId)
    }

    @Test("Update nonexistent race throws raceNotFound")
    func updateNonexistentRaceThrows() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let race = makeRace()

        do {
            try await repo.updateRace(race)
            Issue.record("Expected DomainError.raceNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .raceNotFound)
        }
    }

    // MARK: - Delete

    @Test("Delete race removes it from the store")
    func deleteRace() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let race = makeRace()

        try await repo.saveRace(race)
        let beforeDelete = try await repo.getRace(id: race.id)
        #expect(beforeDelete != nil)

        try await repo.deleteRace(id: race.id)
        let afterDelete = try await repo.getRace(id: race.id)
        #expect(afterDelete == nil)
    }

    @Test("Delete nonexistent race throws raceNotFound")
    func deleteNonexistentRaceThrows() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)

        do {
            try await repo.deleteRace(id: UUID())
            Issue.record("Expected DomainError.raceNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .raceNotFound)
        }
    }

    @Test("Delete only removes the targeted race leaving others intact")
    func deleteOnlyTargetedRace() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)

        let race1 = makeRace(name: "Race 1")
        let race2 = makeRace(name: "Race 2")
        try await repo.saveRace(race1)
        try await repo.saveRace(race2)

        try await repo.deleteRace(id: race1.id)

        let remaining = try await repo.getRaces()
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "Race 2")
    }

    // MARK: - Goal Types

    @Test("Save and fetch race with finish goal preserves goal type")
    func finishGoalPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let race = makeRace(goalType: .finish)

        try await repo.saveRace(race)
        let fetched = try await repo.getRace(id: race.id)

        #expect(fetched?.goalType == .finish)
    }

    @Test("Save and fetch race with target time goal preserves goal type")
    func targetTimeGoalPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let race = makeRace(goalType: .targetTime(24 * 3600))

        try await repo.saveRace(race)
        let fetched = try await repo.getRace(id: race.id)

        #expect(fetched?.goalType == .targetTime(24 * 3600))
    }

    @Test("Save and fetch race with target ranking goal preserves goal type")
    func targetRankingGoalPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let race = makeRace(goalType: .targetRanking(50))

        try await repo.saveRace(race)
        let fetched = try await repo.getRace(id: race.id)

        #expect(fetched?.goalType == .targetRanking(50))
    }

    // MARK: - Checkpoints

    @Test("Save and fetch race with checkpoints preserves checkpoint data")
    func checkpointsPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)

        let checkpoints = [
            makeCheckpoint(name: "Les Contamines", distanceKm: 31, elevationM: 1200),
            makeCheckpoint(name: "Courmayeur", distanceKm: 78, elevationM: 1189)
        ]
        let race = makeRace(checkpoints: checkpoints)

        try await repo.saveRace(race)
        let fetched = try await repo.getRace(id: race.id)

        #expect(fetched?.checkpoints.count == 2)
        // Checkpoints are sorted by distance in the mapper
        #expect(fetched?.checkpoints[0].name == "Les Contamines")
        #expect(fetched?.checkpoints[1].name == "Courmayeur")
    }

    @Test("Update race goal type from finish to target time")
    func updateGoalTypeFinishToTargetTime() async throws {
        let container = try makeContainer()
        let repo = LocalRaceRepository(modelContainer: container)
        let raceId = UUID()

        let original = makeRace(id: raceId, goalType: .finish)
        try await repo.saveRace(original)

        let updated = makeRace(id: raceId, goalType: .targetTime(30 * 3600))
        try await repo.updateRace(updated)

        let fetched = try await repo.getRace(id: raceId)
        #expect(fetched?.goalType == .targetTime(30 * 3600))
    }
}
