import SwiftUI

struct ActivityFeedCard: View {
    let item: ActivityFeedItem
    let relativeTime: String
    let onLike: () -> Void
    let formatDuration: (TimeInterval) -> String
    let formatPace: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            titleSection
            if let stats = item.stats {
                statsRow(stats)
            }
            footer
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            profilePhoto
            VStack(alignment: .leading, spacing: 2) {
                Text(item.athleteDisplayName)
                    .font(.subheadline.bold())
                Text(relativeTime)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            ActivityTypeIcon(activityType: item.activityType)
        }
    }

    private var profilePhoto: some View {
        Group {
            if let photoData = item.athletePhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(item.title)
                .font(.subheadline.bold())
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Stats

    private func statsRow(_ stats: ActivityStats) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            if let distance = stats.distanceKm {
                Label(String(format: "%.1f km", distance), systemImage: "figure.run")
            }
            if let elevation = stats.elevationGainM {
                Label(String(format: "%.0f m", elevation), systemImage: "mountain.2")
            }
            if let duration = stats.duration {
                Label(formatDuration(duration), systemImage: "clock")
            }
            if let pace = stats.averagePace {
                Label(formatPace(pace), systemImage: "speedometer")
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.label)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(action: onLike) {
                Label(
                    "\(item.likeCount)",
                    systemImage: item.isLikedByMe ? "heart.fill" : "heart"
                )
                .foregroundStyle(item.isLikedByMe ? Theme.Colors.danger : Theme.Colors.secondaryLabel)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.likeCount) like\(item.likeCount == 1 ? "" : "s")")
            .accessibilityHint(item.isLikedByMe ? "Removes your like" : "Likes this activity")
            Spacer()
        }
        .font(.caption)
    }
}
