import Foundation

enum ActivityPublisher {

    static func createActivity(
        from run: CompletedRun,
        athleteProfile: SocialProfile
    ) -> ActivityFeedItem {
        let activityType = determineActivityType(for: run)
        let title = buildTitle(for: run, type: activityType)
        let subtitle = buildSubtitle(for: run)

        return ActivityFeedItem(
            id: UUID(),
            athleteProfileId: athleteProfile.id,
            athleteDisplayName: athleteProfile.displayName,
            athletePhotoData: athleteProfile.profilePhotoData,
            activityType: activityType,
            title: title,
            subtitle: subtitle,
            stats: ActivityStats(
                distanceKm: run.distanceKm,
                elevationGainM: run.elevationGainM,
                duration: run.duration,
                averagePace: run.averagePaceSecondsPerKm
            ),
            timestamp: run.date,
            likeCount: 0,
            isLikedByMe: false
        )
    }

    // MARK: - Private Helpers

    private static func determineActivityType(for run: CompletedRun) -> FeedActivityType {
        if run.linkedRaceId != nil {
            return .raceFinished
        }
        return .completedRun
    }

    private static func buildTitle(for run: CompletedRun, type: FeedActivityType) -> String {
        let distanceText = String(format: "%.1f km", run.distanceKm)
        switch type {
        case .raceFinished:
            return "Finished a race: \(distanceText)"
        case .completedRun:
            return "Completed a \(distanceText) run"
        default:
            return "Completed a \(distanceText) run"
        }
    }

    private static func buildSubtitle(for run: CompletedRun) -> String? {
        var parts: [String] = []
        if run.elevationGainM > 0 {
            parts.append(String(format: "%.0f m D+", run.elevationGainM))
        }
        if let notes = run.notes, !notes.isEmpty {
            parts.append(notes)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " - ")
    }
}
