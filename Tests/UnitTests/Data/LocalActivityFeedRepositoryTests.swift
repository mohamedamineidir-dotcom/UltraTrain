import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("Local Activity Feed Repository Tests")
@MainActor
struct LocalActivityFeedRepositoryTests {

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

    private func makeActivity(
        athleteProfileId: String = "athlete-1",
        athleteDisplayName: String = "Runner",
        title: String = "Completed a 10.0 km run",
        subtitle: String? = "500 m D+",
        timestamp: Date = Date.now,
        likeCount: Int = 0,
        isLikedByMe: Bool = false
    ) -> ActivityFeedItem {
        ActivityFeedItem(
            id: UUID(),
            athleteProfileId: athleteProfileId,
            athleteDisplayName: athleteDisplayName,
            athletePhotoData: nil,
            activityType: .completedRun,
            title: title,
            subtitle: subtitle,
            stats: ActivityStats(
                distanceKm: 10.0,
                elevationGainM: 500,
                duration: 3600,
                averagePace: 360
            ),
            timestamp: timestamp,
            likeCount: likeCount,
            isLikedByMe: isLikedByMe
        )
    }

    @Test("Publish and fetch activity")
    func publishAndFetchActivity() async throws {
        let container = try makeContainer()
        let repo = LocalActivityFeedRepository(modelContainer: container)

        let activity = makeActivity(title: "Morning trail run")

        try await repo.publishActivity(activity)
        let feed = try await repo.fetchFeed(limit: 10)

        #expect(feed.count == 1)
        #expect(feed.first?.title == "Morning trail run")
        #expect(feed.first?.athleteDisplayName == "Runner")
        #expect(feed.first?.activityType == .completedRun)
        #expect(feed.first?.stats?.distanceKm == 10.0)
        #expect(feed.first?.stats?.elevationGainM == 500)
    }

    @Test("Fetch feed respects limit")
    func fetchFeedRespectsLimit() async throws {
        let container = try makeContainer()
        let repo = LocalActivityFeedRepository(modelContainer: container)

        for i in 1...5 {
            let activity = makeActivity(title: "Run #\(i)")
            try await repo.publishActivity(activity)
        }

        let limited = try await repo.fetchFeed(limit: 3)
        #expect(limited.count == 3)

        let all = try await repo.fetchFeed(limit: 10)
        #expect(all.count == 5)
    }

    @Test("Toggle like increments like count")
    func toggleLikeIncrementsCount() async throws {
        let container = try makeContainer()
        let repo = LocalActivityFeedRepository(modelContainer: container)

        let activity = makeActivity(likeCount: 0, isLikedByMe: false)
        try await repo.publishActivity(activity)

        try await repo.toggleLike(itemId: activity.id)

        let feed = try await repo.fetchFeed(limit: 10)
        #expect(feed.first?.likeCount == 1)
        #expect(feed.first?.isLikedByMe == true)
    }

    @Test("Toggle like again decrements like count")
    func toggleLikeAgainDecrementsCount() async throws {
        let container = try makeContainer()
        let repo = LocalActivityFeedRepository(modelContainer: container)

        let activity = makeActivity(likeCount: 0, isLikedByMe: false)
        try await repo.publishActivity(activity)

        try await repo.toggleLike(itemId: activity.id)
        try await repo.toggleLike(itemId: activity.id)

        let feed = try await repo.fetchFeed(limit: 10)
        #expect(feed.first?.likeCount == 0)
        #expect(feed.first?.isLikedByMe == false)
    }

    @Test("Feed is sorted by timestamp descending")
    func feedSortedByTimestampDescending() async throws {
        let container = try makeContainer()
        let repo = LocalActivityFeedRepository(modelContainer: container)

        let oldest = makeActivity(
            title: "Oldest",
            timestamp: Date.now.addingTimeInterval(-3600)
        )
        let middle = makeActivity(
            title: "Middle",
            timestamp: Date.now.addingTimeInterval(-1800)
        )
        let newest = makeActivity(
            title: "Newest",
            timestamp: Date.now
        )

        // Insert out of order intentionally
        try await repo.publishActivity(middle)
        try await repo.publishActivity(oldest)
        try await repo.publishActivity(newest)

        let feed = try await repo.fetchFeed(limit: 10)

        #expect(feed.count == 3)
        #expect(feed[0].title == "Newest")
        #expect(feed[1].title == "Middle")
        #expect(feed[2].title == "Oldest")
    }
}
