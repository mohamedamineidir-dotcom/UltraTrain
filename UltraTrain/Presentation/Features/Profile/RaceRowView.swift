import SwiftUI

struct RaceRowView: View {
    @Environment(\.unitPreference) private var units
    let race: Race

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(race.name)
                    .font(.headline)
                Spacer()
                priorityBadge
            }
            HStack(spacing: Theme.Spacing.md) {
                Label(race.date.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                Label(UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                Label("\(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) D+", systemImage: "arrow.up.right")
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            goalLabel
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var priorityBadge: some View {
        Text(race.priority.displayName)
            .font(.caption.bold())
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(race.priority.badgeColor.opacity(0.15))
            .foregroundStyle(race.priority.badgeColor)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var goalLabel: some View {
        switch race.goalType {
        case .finish:
            Label("Goal: Finish", systemImage: "flag.checkered")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        case .targetTime(let seconds):
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            Label("Goal: \(hours)h\(String(format: "%02d", minutes))m",
                  systemImage: "clock")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        case .targetRanking(let rank):
            Label("Goal: Top \(rank)", systemImage: "trophy")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }
}

// MARK: - RacePriority Display

extension RacePriority {
    var displayName: String {
        switch self {
        case .aRace: "A Race"
        case .bRace: "B Race"
        case .cRace: "C Race"
        }
    }

    var badgeColor: Color {
        switch self {
        case .aRace: Theme.Colors.danger
        case .bRace: Theme.Colors.warning
        case .cRace: Theme.Colors.secondaryLabel
        }
    }
}
