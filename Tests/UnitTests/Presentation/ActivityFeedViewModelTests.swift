import Foundation
import Testing
@testable import UltraTrain

@Suite("ActivityFeedViewModel Tests")
struct ActivityFeedViewModelTests {

    // MARK: - Helpers

    private func makeFeedItem(
        id: UUID = UUID(),
        timestamp: Date = .now,
        likeCount: Int = 0,
        isLikedByMe: Bool = false
    ) -> ActivityFeedItem {
        ActivityFeedItem(
            id: id,
            athleteProfileId: "profile-1",
            athleteDisplayName: "Test Runner",
            athletePhotoData: nil,
            activityType: .completedRun,
            title: "Morning Run",
            subtitle: "10K easy run",
            stats: ActivityStats(distanceKm: 10, elevationGainM: 200, duration: 3600, averagePace: 360),
            timestamp: timestamp,
            likeCount: likeCount,
            isLikedByMe: isLikedByMe
        )
    }

    @MainActor
    private func makeSUT(
        repo: MockActivityFeedRepository = MockActivityFeedRepository()
    ) -> (ActivityFeedViewModel, MockActivityFeedRepository) {
        let vm = ActivityFeedViewModel(activityFeedRepository: repo)
        return (vm, repo)
    }

    // MARK: - Tests

    @Test("Load populates feed items and clears loading state")
    @MainActor
    func loadPopulatesFeed() async {
        let repo = MockActivityFeedRepository()
        repo.feedItems = [makeFeedItem(), makeFeedItem()]
        let (vm, _) = makeSUT(repo: repo)

        await vm.load()

        #expect(vm.feedItems.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("Load sets error when repository throws")
    @MainActor
    func loadSetsError() async {
        let failingRepo = FailingActivityFeedRepository()
        let vm = ActivityFeedViewModel(activityFeedRepository: failingRepo)

        await vm.load()

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
        #expect(vm.feedItems.isEmpty)
    }

    @Test("sortedItems returns items newest first")
    @MainActor
    func sortedItemsNewestFirst() {
        let (vm, _) = makeSUT()
        let older = makeFeedItem(timestamp: Date.now.addingTimeInterval(-3600))
        let newer = makeFeedItem(timestamp: Date.now)
        vm.feedItems = [older, newer]

        let sorted = vm.sortedItems

        #expect(sorted.first?.id == newer.id)
        #expect(sorted.last?.id == older.id)
    }

    @Test("toggleLike performs optimistic update on like")
    @MainActor
    func toggleLikeOptimisticUpdate() async {
        let repo = MockActivityFeedRepository()
        let itemId = UUID()
        let item = makeFeedItem(id: itemId, likeCount: 5, isLikedByMe: false)
        repo.feedItems = [item]
        let (vm, _) = makeSUT(repo: repo)
        await vm.load()

        await vm.toggleLike(itemId: itemId)

        #expect(vm.feedItems.first?.isLikedByMe == true)
        #expect(vm.feedItems.first?.likeCount == 6)
        #expect(repo.toggledLikeId == itemId)
    }

    @Test("toggleLike performs optimistic update on unlike")
    @MainActor
    func toggleUnlikeOptimisticUpdate() async {
        let repo = MockActivityFeedRepository()
        let itemId = UUID()
        let item = makeFeedItem(id: itemId, likeCount: 3, isLikedByMe: true)
        repo.feedItems = [item]
        let (vm, _) = makeSUT(repo: repo)
        await vm.load()

        await vm.toggleLike(itemId: itemId)

        #expect(vm.feedItems.first?.isLikedByMe == false)
        #expect(vm.feedItems.first?.likeCount == 2)
    }

    @Test("formattedDuration returns hours and minutes for long durations")
    @MainActor
    func formattedDurationWithHours() {
        let (vm, _) = makeSUT()

        let result = vm.formattedDuration(5400) // 1h 30m
        #expect(result == "1h 30m")
    }

    @Test("formattedDuration returns minutes only for short durations")
    @MainActor
    func formattedDurationMinutesOnly() {
        let (vm, _) = makeSUT()

        let result = vm.formattedDuration(2400) // 40m
        #expect(result == "40m")
    }

    @Test("formattedPace returns correct pace string")
    @MainActor
    func formattedPace() {
        let (vm, _) = makeSUT()

        let result = vm.formattedPace(330) // 5:30 /km
        #expect(result == "5:30 /km")
    }
}

// MARK: - Test Double

private final class FailingActivityFeedRepository: ActivityFeedRepository, @unchecked Sendable {
    func fetchFeed(limit: Int) async throws -> [ActivityFeedItem] {
        throw DomainError.networkUnavailable
    }
    func publishActivity(_ item: ActivityFeedItem) async throws {}
    func toggleLike(itemId: UUID) async throws {}
}
