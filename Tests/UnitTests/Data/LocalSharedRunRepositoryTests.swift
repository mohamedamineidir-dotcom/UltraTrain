import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalSharedRunRepository Tests")
@MainActor
struct LocalSharedRunRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            SocialProfileSwiftDataModel.self,
            FriendConnectionSwiftDataModel.self,
            SharedRunSwiftDataModel.self,
            ActivityFeedItemSwiftDataModel.self,
            GroupChallengeSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeSharedRun(
        id: UUID = UUID(),
        sharedByProfileId: String = "runner-1",
        distanceKm: Double = 21.1,
        sharedAt: Date = Date()
    ) -> SharedRun {
        SharedRun(
            id: id,
            sharedByProfileId: sharedByProfileId,
            sharedByDisplayName: "Trail Runner",
            date: Date(),
            distanceKm: distanceKm,
            elevationGainM: 1200,
            elevationLossM: 1150,
            duration: 7200,
            averagePaceSecondsPerKm: 341,
            gpsTrack: [],
            splits: [],
            notes: "Beautiful trail run",
            sharedAt: sharedAt,
            likeCount: 0,
            commentCount: 0
        )
    }

    @Test("Share and fetch shared runs")
    func shareAndFetchSharedRuns() async throws {
        let container = try makeContainer()
        let repo = LocalSharedRunRepository(modelContainer: container)

        let run = makeSharedRun(distanceKm: 42.0)
        try await repo.shareRun(run, withFriendIds: ["friend-1", "friend-2"])

        let results = try await repo.fetchSharedRuns()
        #expect(results.count == 1)
        #expect(results.first?.distanceKm == 42.0)
    }

    @Test("Fetch shared runs returns empty when none")
    func fetchSharedRunsReturnsEmptyWhenNone() async throws {
        let container = try makeContainer()
        let repo = LocalSharedRunRepository(modelContainer: container)

        let results = try await repo.fetchSharedRuns()
        #expect(results.isEmpty)
    }

    @Test("Revoke share removes the run")
    func revokeShareRemovesTheRun() async throws {
        let container = try makeContainer()
        let repo = LocalSharedRunRepository(modelContainer: container)
        let runId = UUID()

        try await repo.shareRun(makeSharedRun(id: runId), withFriendIds: [])
        try await repo.revokeShare(runId)

        let results = try await repo.fetchSharedRuns()
        #expect(results.isEmpty)
    }

    @Test("Revoke share throws when run not found")
    func revokeShareThrowsWhenNotFound() async throws {
        let container = try makeContainer()
        let repo = LocalSharedRunRepository(modelContainer: container)

        await #expect(throws: DomainError.self) {
            try await repo.revokeShare(UUID())
        }
    }

    @Test("Fetch runs shared by me returns all shared runs")
    func fetchRunsSharedByMeReturnsAllShared() async throws {
        let container = try makeContainer()
        let repo = LocalSharedRunRepository(modelContainer: container)

        try await repo.shareRun(makeSharedRun(distanceKm: 10.0), withFriendIds: [])
        try await repo.shareRun(makeSharedRun(distanceKm: 20.0), withFriendIds: [])

        let results = try await repo.fetchRunsSharedByMe()
        #expect(results.count == 2)
    }

    @Test("Shared runs ordered by sharedAt descending")
    func sharedRunsOrderedBySharedAtDescending() async throws {
        let container = try makeContainer()
        let repo = LocalSharedRunRepository(modelContainer: container)

        let older = makeSharedRun(
            distanceKm: 10.0,
            sharedAt: Date.now.addingTimeInterval(-3600)
        )
        let newer = makeSharedRun(
            distanceKm: 30.0,
            sharedAt: Date.now
        )

        try await repo.shareRun(older, withFriendIds: [])
        try await repo.shareRun(newer, withFriendIds: [])

        let results = try await repo.fetchSharedRuns()
        #expect(results[0].distanceKm == 30.0)
        #expect(results[1].distanceKm == 10.0)
    }
}
