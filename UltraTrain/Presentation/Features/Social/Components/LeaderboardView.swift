import SwiftUI

struct LeaderboardView: View {
    let challenge: GroupChallenge
    var currentProfileId: String?

    private var rankedParticipants: [GroupChallengeProgressCalculator.RankedParticipant] {
        GroupChallengeProgressCalculator.leaderboard(for: challenge)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Leaderboard")
                .font(.headline)

            if rankedParticipants.isEmpty {
                Text("No participants yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.md)
            } else {
                ForEach(rankedParticipants, id: \.participant.id) { entry in
                    participantRow(entry)
                }
            }
        }
    }

    // MARK: - Participant Row

    private func participantRow(_ entry: GroupChallengeProgressCalculator.RankedParticipant) -> some View {
        let isCurrentUser = entry.participant.id == currentProfileId
        return HStack(spacing: Theme.Spacing.sm) {
            rankView(entry.rank)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(entry.participant.displayName)
                    .font(.subheadline)
                    .fontWeight(isCurrentUser ? .bold : .regular)
                    .foregroundStyle(isCurrentUser ? Theme.Colors.primary : Theme.Colors.label)
                ProgressView(value: entry.progressPercent)
                    .tint(isCurrentUser ? Theme.Colors.primary : Theme.Colors.secondaryLabel)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", entry.participant.currentValue))
                    .font(.subheadline.bold().monospacedDigit())
                Text(challenge.unitLabel)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(entry.rank), \(entry.participant.displayName), \(String(format: "%.1f", entry.participant.currentValue)) \(challenge.unitLabel), \(Int(entry.progressPercent * 100)) percent")
    }

    // MARK: - Rank Badge

    private func rankView(_ rank: Int) -> some View {
        Group {
            switch rank {
            case 1:
                Image(systemName: "medal.fill")
                    .foregroundStyle(.yellow)
            case 2:
                Image(systemName: "medal.fill")
                    .foregroundStyle(.gray)
            case 3:
                Image(systemName: "medal.fill")
                    .foregroundStyle(.brown)
            default:
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 24, alignment: .center)
        .accessibilityLabel("Rank \(rank)")
    }
}
