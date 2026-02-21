import SwiftUI

struct GroupChallengeCard: View {
    let challenge: GroupChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            headerRow
            progressSection
            footerRow
        }
        .cardStyle()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: typeIcon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.primary)
            Text(challenge.name)
                .font(.subheadline.bold())
                .lineLimit(1)
            Spacer()
            daysRemainingBadge
        }
    }

    private var typeIcon: String {
        switch challenge.type {
        case .distance: return "figure.run"
        case .elevation: return "mountain.2"
        case .consistency: return "checkmark.seal"
        case .streak: return "flame"
        }
    }

    private var daysRemainingBadge: some View {
        Text("\(challenge.daysRemaining)d left")
            .font(.caption2.bold())
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                challenge.daysRemaining <= 3
                    ? Theme.Colors.warning.opacity(0.2)
                    : Theme.Colors.primary.opacity(0.2)
            )
            .clipShape(Capsule())
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ProgressView(value: leaderProgress)
                .tint(Theme.Colors.primary)
            Text(String(format: "%.0f%%", leaderProgress * 100))
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var leaderProgress: Double {
        GroupChallengeProgressCalculator.leaderProgress(for: challenge)
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Label("\(challenge.participants.count)", systemImage: "person.2")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            Text(String(format: "%.0f %@", challenge.targetValue, challenge.unitLabel))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}
