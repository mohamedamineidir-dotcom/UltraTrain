import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalRunRepository Tests")
@MainActor
struct LocalRunRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            CompletedRunSwiftDataModel.self,
            SplitSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeRun(
        id: UUID = UUID(),
        athleteId: UUID = UUID(),
        date: Date = Date(),
        distanceKm: Double = 15.0,
        elevationGainM: Double = 500,
        elevationLossM: Double = 450,
        duration: TimeInterval = 5400,
        averagePaceSecondsPerKm: Double = 360,
        notes: String? = nil,
        rpe: Int? = nil,
        perceivedFeeling: PerceivedFeeling? = nil,
        terrainType: TerrainType? = nil,
        stravaActivityId: Int? = nil,
        isStravaImport: Bool = false,
        isHealthKitImport: Bool = false,
        healthKitWorkoutUUID: String? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: id,
            athleteId: athleteId,
            date: date,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: averagePaceSecondsPerKm,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: notes,
            pausedDuration: 0,
            stravaActivityId: stravaActivityId,
            isStravaImport: isStravaImport,
            isHealthKitImport: isHealthKitImport,
            healthKitWorkoutUUID: healthKitWorkoutUUID,
            rpe: rpe,
            perceivedFeeling: perceivedFeeling,
            terrainType: terrainType
        )
    }

    // MARK: - Save & Fetch

    @Test("Save run and fetch by ID returns the saved run")
    func saveAndFetchById() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)
        let run = makeRun()

        try await repo.saveRun(run)
        let fetched = try await repo.getRun(id: run.id)

        #expect(fetched != nil)
        #expect(fetched?.id == run.id)
        #expect(fetched?.distanceKm == run.distanceKm)
        #expect(fetched?.elevationGainM == run.elevationGainM)
        #expect(fetched?.duration == run.duration)
        #expect(fetched?.averagePaceSecondsPerKm == run.averagePaceSecondsPerKm)
    }

    @Test("Fetch run with nonexistent ID returns nil")
    func fetchNonexistentRunReturnsNil() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        let fetched = try await repo.getRun(id: UUID())
        #expect(fetched == nil)
    }

    // MARK: - Get Runs for Athlete

    @Test("Get runs for athlete returns only that athlete's runs sorted by date descending")
    func getRunsForAthlete() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)
        let athleteId = UUID()
        let otherAthleteId = UUID()

        let oldDate = Date(timeIntervalSince1970: 1_000_000)
        let newDate = Date(timeIntervalSince1970: 2_000_000)

        let run1 = makeRun(athleteId: athleteId, date: oldDate, distanceKm: 10)
        let run2 = makeRun(athleteId: athleteId, date: newDate, distanceKm: 20)
        let run3 = makeRun(athleteId: otherAthleteId, distanceKm: 30)

        try await repo.saveRun(run1)
        try await repo.saveRun(run2)
        try await repo.saveRun(run3)

        let athleteRuns = try await repo.getRuns(for: athleteId)

        #expect(athleteRuns.count == 2)
        // Sorted by date descending (newest first)
        #expect(athleteRuns[0].distanceKm == 20)
        #expect(athleteRuns[1].distanceKm == 10)
    }

    @Test("Get runs for athlete with no runs returns empty array")
    func getRunsForAthleteEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        let runs = try await repo.getRuns(for: UUID())
        #expect(runs.isEmpty)
    }

    // MARK: - Recent Runs

    @Test("Get recent runs respects limit and returns newest first")
    func getRecentRunsWithLimit() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        for i in 0..<5 {
            let run = makeRun(
                date: Date(timeIntervalSince1970: Double(i) * 100_000),
                distanceKm: Double(i + 1) * 5
            )
            try await repo.saveRun(run)
        }

        let recent = try await repo.getRecentRuns(limit: 3)

        #expect(recent.count == 3)
        // Newest first: 25km, 20km, 15km
        #expect(recent[0].distanceKm == 25)
        #expect(recent[1].distanceKm == 20)
        #expect(recent[2].distanceKm == 15)
    }

    @Test("Get recent runs with limit larger than available returns all runs")
    func getRecentRunsLimitExceedsCount() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        let run = makeRun()
        try await repo.saveRun(run)

        let recent = try await repo.getRecentRuns(limit: 10)
        #expect(recent.count == 1)
    }

    // MARK: - Delete

    @Test("Delete run removes it from the store")
    func deleteRun() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)
        let run = makeRun()

        try await repo.saveRun(run)
        let beforeDelete = try await repo.getRun(id: run.id)
        #expect(beforeDelete != nil)

        try await repo.deleteRun(id: run.id)
        let afterDelete = try await repo.getRun(id: run.id)
        #expect(afterDelete == nil)
    }

    @Test("Delete nonexistent run does not throw")
    func deleteNonexistentRunNoThrow() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        // Should not throw when run doesn't exist
        try await repo.deleteRun(id: UUID())
    }

    // MARK: - Update

    @Test("Update run modifies fields on existing run")
    func updateRunModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        var run = makeRun(notes: "Original notes", rpe: 5)
        try await repo.saveRun(run)

        run.notes = "Updated notes"
        run.rpe = 8
        run.perceivedFeeling = .tough
        run.terrainType = .mountain
        run.stravaActivityId = 12345
        run.isStravaImport = true
        run.isHealthKitImport = true
        run.healthKitWorkoutUUID = "hk-uuid-123"

        try await repo.updateRun(run)

        let fetched = try await repo.getRun(id: run.id)
        #expect(fetched?.notes == "Updated notes")
        #expect(fetched?.rpe == 8)
        #expect(fetched?.perceivedFeeling == .tough)
        #expect(fetched?.terrainType == .mountain)
        #expect(fetched?.stravaActivityId == 12345)
        #expect(fetched?.isStravaImport == true)
        #expect(fetched?.isHealthKitImport == true)
        #expect(fetched?.healthKitWorkoutUUID == "hk-uuid-123")
    }

    @Test("Update nonexistent run throws persistenceError")
    func updateNonexistentRunThrows() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        let run = makeRun()

        do {
            try await repo.updateRun(run)
            Issue.record("Expected DomainError.persistenceError to be thrown")
        } catch let error as DomainError {
            #expect(error == .persistenceError(message: "Run not found for update"))
        }
    }

    // MARK: - Update Linked Session

    @Test("Update linked session sets linkedSessionId on existing run")
    func updateLinkedSession() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)
        let run = makeRun()
        let sessionId = UUID()

        try await repo.saveRun(run)
        try await repo.updateLinkedSession(runId: run.id, sessionId: sessionId)

        let fetched = try await repo.getRun(id: run.id)
        #expect(fetched?.linkedSessionId == sessionId)
    }

    @Test("Update linked session on nonexistent run throws persistenceError")
    func updateLinkedSessionNonexistentRunThrows() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)

        do {
            try await repo.updateLinkedSession(runId: UUID(), sessionId: UUID())
            Issue.record("Expected DomainError.persistenceError to be thrown")
        } catch let error as DomainError {
            #expect(error == .persistenceError(message: "Run not found for linking"))
        }
    }

    // MARK: - Multiple Saves

    @Test("Saving multiple runs for the same athlete stores all of them")
    func saveMultipleRunsSameAthlete() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)
        let athleteId = UUID()

        for i in 0..<4 {
            let run = makeRun(
                athleteId: athleteId,
                date: Date(timeIntervalSince1970: Double(i) * 86400),
                distanceKm: Double(i + 1) * 10
            )
            try await repo.saveRun(run)
        }

        let runs = try await repo.getRuns(for: athleteId)
        #expect(runs.count == 4)
    }

    @Test("Athlete ID is preserved through save and fetch round-trip")
    func athleteIdPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRunRepository(modelContainer: container)
        let athleteId = UUID()
        let run = makeRun(athleteId: athleteId)

        try await repo.saveRun(run)
        let fetched = try await repo.getRun(id: run.id)

        #expect(fetched?.athleteId == athleteId)
    }
}
