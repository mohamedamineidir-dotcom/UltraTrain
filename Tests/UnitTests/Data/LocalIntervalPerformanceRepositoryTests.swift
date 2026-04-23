import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalIntervalPerformanceRepository Tests")
@MainActor
struct LocalIntervalPerformanceRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([IntervalPerformanceFeedbackSwiftDataModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeFeedback(
        sessionId: UUID = UUID(),
        type: SessionType = .intervals,
        target: Double = 252,
        paces: [Double] = [],
        rpe: Int = 7,
        completed: Bool = true,
        createdAt: Date = Date()
    ) -> IntervalPerformanceFeedback {
        IntervalPerformanceFeedback(
            id: UUID(),
            sessionId: sessionId,
            sessionType: type,
            targetPacePerKmAtTime: target,
            prescribedRepCount: 6,
            actualPacesPerKm: paces,
            completedAllReps: completed,
            perceivedEffort: rpe,
            notes: nil,
            createdAt: createdAt
        )
    }

    @Test("Save and fetch a feedback entry")
    func saveAndFetch() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalPerformanceRepository(modelContainer: container)
        let sessionId = UUID()

        try await repo.save(makeFeedback(sessionId: sessionId, paces: [252, 254, 258]))

        let fetched = try await repo.get(for: sessionId)
        #expect(fetched != nil)
        #expect(fetched?.actualPacesPerKm == [252, 254, 258])
    }

    @Test("Re-saving for the same sessionId replaces the prior entry")
    func replacesPriorEntry() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalPerformanceRepository(modelContainer: container)
        let sessionId = UUID()

        try await repo.save(makeFeedback(sessionId: sessionId, rpe: 7))
        try await repo.save(makeFeedback(sessionId: sessionId, rpe: 9))

        let all = try await repo.getAll()
        #expect(all.count == 1)
        #expect(all.first?.perceivedEffort == 9)
    }

    @Test("getRecent filters by cutoff and session type")
    func getRecentFiltersCorrectly() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalPerformanceRepository(modelContainer: container)

        let old = Date().addingTimeInterval(-30 * 24 * 3600)
        let fresh = Date().addingTimeInterval(-2 * 24 * 3600)

        try await repo.save(makeFeedback(type: .intervals, createdAt: old))
        try await repo.save(makeFeedback(type: .intervals, createdAt: fresh))
        try await repo.save(makeFeedback(type: .tempo, createdAt: fresh))

        let cutoff = Date().addingTimeInterval(-21 * 24 * 3600)
        let intervals = try await repo.getRecent(since: cutoff, sessionType: .intervals)

        #expect(intervals.count == 1)
        #expect(intervals.first?.sessionType == .intervals)
    }

    @Test("Empty actual paces round-trip correctly")
    func emptyPacesRoundTrip() async throws {
        let container = try makeContainer()
        let repo = LocalIntervalPerformanceRepository(modelContainer: container)
        let sessionId = UUID()

        try await repo.save(makeFeedback(sessionId: sessionId, paces: []))

        let fetched = try await repo.get(for: sessionId)
        #expect(fetched?.actualPacesPerKm.isEmpty == true)
        #expect(fetched?.meanActualPacePerKm == nil)
        #expect(fetched?.meanDeviationSecondsPerKm == nil)
    }

    @Test("Mean deviation is positive when actual is slower than target")
    func meanDeviationPositiveWhenSlower() async throws {
        let fb = makeFeedback(target: 250, paces: [255, 257, 258])
        // mean 256.67 - 250 = +6.67
        #expect(fb.meanDeviationSecondsPerKm != nil)
        if let deviation = fb.meanDeviationSecondsPerKm {
            #expect(deviation > 6)
            #expect(deviation < 7)
        }
    }
}
