import Foundation
import os

@Observable
@MainActor
final class ActivityFeedViewModel {

    // MARK: - Dependencies

    private let activityFeedRepository: any ActivityFeedRepository

    // MARK: - State

    var feedItems: [ActivityFeedItem] = []
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(activityFeedRepository: any ActivityFeedRepository) {
        self.activityFeedRepository = activityFeedRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil
        do {
            feedItems = try await activityFeedRepository.fetchFeed(limit: 50)
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to load activity feed: \(error)")
        }
        isLoading = false
    }

    // MARK: - Computed

    var sortedItems: [ActivityFeedItem] {
        feedItems.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Like

    func toggleLike(itemId: UUID) async {
        // Optimistic update
        if let index = feedItems.firstIndex(where: { $0.id == itemId }) {
            let wasLiked = feedItems[index].isLikedByMe
            feedItems[index].isLikedByMe = !wasLiked
            feedItems[index].likeCount += wasLiked ? -1 : 1
        }

        do {
            try await activityFeedRepository.toggleLike(itemId: itemId)
        } catch {
            // Revert optimistic update
            if let index = feedItems.firstIndex(where: { $0.id == itemId }) {
                let wasLiked = feedItems[index].isLikedByMe
                feedItems[index].isLikedByMe = !wasLiked
                feedItems[index].likeCount += wasLiked ? -1 : 1
            }
            self.error = error.localizedDescription
            Logger.social.error("Failed to toggle like: \(error)")
        }
    }

    // MARK: - Formatting

    func relativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date.now)
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }

    func formattedPace(_ secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}
