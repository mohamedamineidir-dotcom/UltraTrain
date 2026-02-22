import SwiftUI

struct UpcomingRacesCard: View {
    @Environment(\.unitPreference) private var units
    let races: [Race]

    var body: some View {
        if !races.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Upcoming Races")
                    .font(.headline)

                ForEach(races) { race in
                    raceRow(race)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func raceRow(_ race: Race) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(race.priority.badgeColor)
                .frame(width: 4, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(race.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0)) · \(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) D+")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(daysUntilText(race.date))
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.primary)
                Text(race.priority.displayName)
                    .font(.caption2)
                    .foregroundStyle(race.priority.badgeColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(race.name), \(race.priority.displayName) race. \(UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0)), \(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) elevation gain. \(daysUntilText(race.date))")
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: date.startOfDay).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days < 7 { return "In \(days) days" }
        let weeks = days / 7
        if weeks == 1 { return "In 1 week" }
        return "In \(weeks) weeks"
    }
}
