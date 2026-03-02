import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalRaceReflectionRepository Tests")
@MainActor
struct LocalRaceReflectionRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([RaceReflectionSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeReflection(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        actualFinishTime: TimeInterval = 43200,
        overallSatisfaction: Int = 8
    ) -> RaceReflection {
        RaceReflection(
            id: id,
            raceId: raceId,
            completedRunId: UUID(),
            actualFinishTime: actualFinishTime,
            actualPosition: 42,
            pacingAssessment: .wellPaced,
            pacingNotes: "Good first half pacing",
            nutritionAssessment: .goodEnough,
            nutritionNotes: "Could have eaten more in the last quarter",
            hadStomachIssues: false,
            weatherImpact: .minor,
            weatherNotes: "Light rain",
            overallSatisfaction: overallSatisfaction,
            keyTakeaways: "Need more hill training",
            createdAt: Date()
        )
    }

    @Test("Save and get reflection for race")
    func saveAndGetReflectionForRace() async throws {
        let container = try makeContainer()
        let repo = LocalRaceReflectionRepository(modelContainer: container)
        let raceId = UUID()

        try await repo.saveReflection(makeReflection(raceId: raceId, overallSatisfaction: 9))

        let fetched = try await repo.getReflection(for: raceId)
        #expect(fetched != nil)
        #expect(fetched?.raceId == raceId)
        #expect(fetched?.overallSatisfaction == 9)
        #expect(fetched?.pacingAssessment == .wellPaced)
    }

    @Test("Get reflection returns nil for unknown race")
    func getReflectionReturnsNilForUnknownRace() async throws {
        let container = try makeContainer()
        let repo = LocalRaceReflectionRepository(modelContainer: container)

        let fetched = try await repo.getReflection(for: UUID())
        #expect(fetched == nil)
    }

    @Test("Save reflection replaces existing for same race")
    func saveReflectionReplacesExistingForSameRace() async throws {
        let container = try makeContainer()
        let repo = LocalRaceReflectionRepository(modelContainer: container)
        let raceId = UUID()

        try await repo.saveReflection(makeReflection(raceId: raceId, actualFinishTime: 40000))
        try await repo.saveReflection(makeReflection(raceId: raceId, actualFinishTime: 45000))

        let fetched = try await repo.getReflection(for: raceId)
        #expect(fetched?.actualFinishTime == 45000)
    }

    @Test("All fields preserved through save and fetch")
    func allFieldsPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalRaceReflectionRepository(modelContainer: container)
        let raceId = UUID()

        let reflection = makeReflection(raceId: raceId)
        try await repo.saveReflection(reflection)

        let fetched = try await repo.getReflection(for: raceId)
        #expect(fetched?.hadStomachIssues == false)
        #expect(fetched?.weatherImpact == .minor)
        #expect(fetched?.nutritionAssessment == .goodEnough)
        #expect(fetched?.actualPosition == 42)
        #expect(fetched?.keyTakeaways == "Need more hill training")
    }

    @Test("Reflections for different races are independent")
    func reflectionsForDifferentRacesIndependent() async throws {
        let container = try makeContainer()
        let repo = LocalRaceReflectionRepository(modelContainer: container)
        let raceId1 = UUID()
        let raceId2 = UUID()

        try await repo.saveReflection(makeReflection(raceId: raceId1, overallSatisfaction: 7))
        try await repo.saveReflection(makeReflection(raceId: raceId2, overallSatisfaction: 9))

        let fetched1 = try await repo.getReflection(for: raceId1)
        let fetched2 = try await repo.getReflection(for: raceId2)
        #expect(fetched1?.overallSatisfaction == 7)
        #expect(fetched2?.overallSatisfaction == 9)
    }
}
