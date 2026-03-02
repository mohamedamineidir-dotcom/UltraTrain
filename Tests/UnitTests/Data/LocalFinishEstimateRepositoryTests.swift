import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalFinishEstimateRepository Tests")
@MainActor
struct LocalFinishEstimateRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([FinishEstimateSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeEstimate(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        athleteId: UUID = UUID(),
        calculatedAt: Date = Date(),
        optimisticTime: TimeInterval = 36000,
        expectedTime: TimeInterval = 43200,
        conservativeTime: TimeInterval = 50400,
        confidencePercent: Double = 75.0,
        raceResultsUsed: Int = 3,
        calibrationFactor: Double = 1.0
    ) -> FinishEstimate {
        FinishEstimate(
            id: id,
            raceId: raceId,
            athleteId: athleteId,
            calculatedAt: calculatedAt,
            optimisticTime: optimisticTime,
            expectedTime: expectedTime,
            conservativeTime: conservativeTime,
            checkpointSplits: [],
            confidencePercent: confidencePercent,
            raceResultsUsed: raceResultsUsed,
            calibrationFactor: calibrationFactor
        )
    }

    // MARK: - Save & Fetch

    @Test("Save estimate and fetch by race ID")
    func saveAndFetchByRaceId() async throws {
        let container = try makeContainer()
        let repo = LocalFinishEstimateRepository(modelContainer: container)
        let raceId = UUID()
        let estimate = makeEstimate(raceId: raceId, expectedTime: 43200)

        try await repo.saveEstimate(estimate)
        let fetched = try await repo.getEstimate(for: raceId)

        #expect(fetched != nil)
        #expect(fetched?.raceId == raceId)
        #expect(fetched?.expectedTime == 43200)
        #expect(fetched?.optimisticTime == 36000)
        #expect(fetched?.conservativeTime == 50400)
    }

    @Test("Get estimate returns nil when none exists")
    func getEstimateReturnsNilWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalFinishEstimateRepository(modelContainer: container)

        let fetched = try await repo.getEstimate(for: UUID())
        #expect(fetched == nil)
    }

    @Test("Save estimate replaces existing estimate for same race")
    func saveEstimateReplacesExisting() async throws {
        let container = try makeContainer()
        let repo = LocalFinishEstimateRepository(modelContainer: container)
        let raceId = UUID()

        let estimate1 = makeEstimate(raceId: raceId, expectedTime: 40000)
        try await repo.saveEstimate(estimate1)

        let estimate2 = makeEstimate(raceId: raceId, expectedTime: 45000)
        try await repo.saveEstimate(estimate2)

        let fetched = try await repo.getEstimate(for: raceId)
        #expect(fetched?.expectedTime == 45000)
    }

    // MARK: - Multiple Races

    @Test("Estimates for different races are independent")
    func estimatesForDifferentRacesIndependent() async throws {
        let container = try makeContainer()
        let repo = LocalFinishEstimateRepository(modelContainer: container)

        let raceId1 = UUID()
        let raceId2 = UUID()
        try await repo.saveEstimate(makeEstimate(raceId: raceId1, expectedTime: 30000))
        try await repo.saveEstimate(makeEstimate(raceId: raceId2, expectedTime: 60000))

        let fetched1 = try await repo.getEstimate(for: raceId1)
        let fetched2 = try await repo.getEstimate(for: raceId2)

        #expect(fetched1?.expectedTime == 30000)
        #expect(fetched2?.expectedTime == 60000)
    }

    // MARK: - Round-trip Values

    @Test("All fields preserved through save and fetch round-trip")
    func allFieldsPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalFinishEstimateRepository(modelContainer: container)
        let raceId = UUID()
        let athleteId = UUID()

        let estimate = makeEstimate(
            raceId: raceId,
            athleteId: athleteId,
            optimisticTime: 28800,
            expectedTime: 36000,
            conservativeTime: 43200,
            confidencePercent: 82.5,
            raceResultsUsed: 5,
            calibrationFactor: 1.05
        )
        try await repo.saveEstimate(estimate)

        let fetched = try await repo.getEstimate(for: raceId)
        #expect(fetched?.athleteId == athleteId)
        #expect(fetched?.confidencePercent == 82.5)
        #expect(fetched?.raceResultsUsed == 5)
        #expect(fetched?.calibrationFactor == 1.05)
    }

    @Test("Save returns most recent estimate when multiple saved for same race")
    func saveMostRecentReturned() async throws {
        let container = try makeContainer()
        let repo = LocalFinishEstimateRepository(modelContainer: container)
        let raceId = UUID()

        let older = makeEstimate(
            raceId: raceId,
            calculatedAt: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            expectedTime: 40000
        )
        try await repo.saveEstimate(older)

        let newer = makeEstimate(
            raceId: raceId,
            calculatedAt: Date(),
            expectedTime: 38000
        )
        try await repo.saveEstimate(newer)

        let fetched = try await repo.getEstimate(for: raceId)
        #expect(fetched?.expectedTime == 38000)
    }
}
