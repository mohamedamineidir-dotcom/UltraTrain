import SwiftUI

struct RaceCalendarRow: View {
    let week: TrainingWeek
    let race: Race?
    let isCurrentWeek: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            phaseBar
                .accessibilityHidden(true)
            weekInfo
            Spacer()
            if let race {
                raceMarker(race)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(isCurrentWeek ? Theme.Colors.primary.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        var label = "Week \(week.weekNumber), \(week.phase.displayName) phase"
        if isCurrentWeek {
            label += ", current week"
        }
        if week.isRecoveryWeek && week.phase != .recovery {
            label += ", recovery"
        }
        label += ". \(dateRange)"
        if let race {
            label += ". Race: \(race.name), \(Int(race.distanceKm)) kilometers"
        }
        return label
    }

    private var phaseBar: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(week.phase.color)
            .frame(width: 4, height: 36)
    }

    private var weekInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Theme.Spacing.xs) {
                Text("W\(week.weekNumber)")
                    .font(.subheadline.bold())
                PhaseBadge(phase: week.phase)
                if week.isRecoveryWeek && week.phase != .recovery {
                    Text("Recovery")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            Text(dateRange)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var dateRange: String {
        let start = week.startDate.formatted(.dateTime.month(.abbreviated).day())
        let end = week.endDate.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }

    private func raceMarker(_ race: Race) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(race.name)
                .font(.caption.bold())
                .lineLimit(1)
            Text("\(Int(race.distanceKm)) km")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(race.priority.badgeColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
