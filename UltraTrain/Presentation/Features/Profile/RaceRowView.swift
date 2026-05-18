import SwiftUI

struct RaceRowView: View {
    @Environment(\.unitPreference) private var units
    let race: Race

    var body: some View {
        // Compact 2-line layout. Was 3 lines (name+badge / date+dist+
        // elev / goal). The goal now sits inline with the stats on
        // line 2 so the row reads as a tight summary, and List's
        // default row insets are no longer compounded by extra
        // internal vertical padding.
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(race.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 4)
                priorityBadge
            }
            HStack(spacing: 10) {
                infoItem(icon: "calendar", text: shortDate)
                infoItem(icon: "point.topleft.down.to.point.bottomright.curvepath",
                         text: UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0))
                infoItem(icon: "arrow.up.right",
                         text: "\(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) D+")
                Spacer(minLength: 4)
                infoItem(icon: goalIcon, text: goalText)
            }
            .font(.caption2)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .lineLimit(1)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(raceAccessibilityLabel)
    }

    private func infoItem(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2.weight(.medium))
        }
    }

    /// Day + month without year. Year-strings on every row added
    /// horizontal weight that pushed the elevation chip off the line
    /// on smaller phones; for upcoming races the year is rarely
    /// ambiguous in context.
    private var shortDate: String {
        race.date.formatted(.dateTime.day().month(.abbreviated))
    }

    private var raceAccessibilityLabel: String {
        let dateStr = race.date.formatted(date: .abbreviated, time: .omitted)
        let distance = AccessibilityFormatters.distance(race.distanceKm, unit: units)
        let elevation = AccessibilityFormatters.elevation(race.elevationGainM, unit: units)
        let goal: String = switch race.goalType {
        case .finish: "Goal: Finish"
        case .targetTime(let seconds):
            "Goal: \(AccessibilityFormatters.duration(seconds))"
        case .targetRanking(let rank):
            "Goal: Top \(rank)"
        }
        return "\(race.name), \(race.priority.displayName), \(dateStr), \(distance), \(elevation), \(goal)"
    }

    private var priorityBadge: some View {
        // Shrunk from .caption / sm-horizontal / xs-vertical padding
        // to caption2 / 6pt / 2pt so the badge takes less of the row
        // and leaves the name room to breathe.
        Text(race.priority.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(race.priority.badgeColor.opacity(0.18))
            .foregroundStyle(race.priority.badgeColor)
            .clipShape(Capsule())
    }

    private var goalText: String {
        switch race.goalType {
        case .finish: return "Finish"
        case .targetTime(let seconds):
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            if hours > 0 {
                return "\(hours)h\(String(format: "%02d", minutes))"
            }
            return "\(minutes) min"
        case .targetRanking(let rank):
            return "Top \(rank)"
        }
    }

    private var goalIcon: String {
        switch race.goalType {
        case .finish:        return "flag.checkered"
        case .targetTime:    return "clock"
        case .targetRanking: return "trophy"
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
