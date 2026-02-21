import SwiftUI

struct SharedRunCard: View {
    let run: SharedRun
    let formattedPace: String
    let formattedDuration: String
    let formattedDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            statsRow
            if let notes = run.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(2)
            }
            footer
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "person.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.sharedByDisplayName)
                    .font(.subheadline.bold())
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Label(String(format: "%.1f km", run.distanceKm), systemImage: "figure.run")
            Label(formattedPace, systemImage: "speedometer")
            Label(formattedDuration, systemImage: "clock")
            Label(String(format: "%.0f m", run.elevationGainM), systemImage: "mountain.2")
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.label)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Theme.Spacing.md) {
            Label("\(run.likeCount)", systemImage: "heart")
            Label("\(run.commentCount)", systemImage: "bubble.right")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }
}
