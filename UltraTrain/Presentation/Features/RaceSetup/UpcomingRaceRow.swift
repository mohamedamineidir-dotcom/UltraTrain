import SwiftUI

struct UpcomingRaceRow: View {
    @Environment(\.unitPreference) private var units
    let race: Race

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(race.priority.badgeColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(race.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(relativeDateString)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0))
                    .font(.caption.bold())
                Text("\(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) D+")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var relativeDateString: String {
        let days = Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: race.date.startOfDay).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days < 7 { return "In \(days) days" }
        let weeks = days / 7
        if weeks == 1 { return "In 1 week" }
        if weeks < 8 { return "In \(weeks) weeks" }
        let months = days / 30
        if months == 1 { return "In 1 month" }
        return "In \(months) months"
    }
}
