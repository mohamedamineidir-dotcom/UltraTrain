import SwiftUI

struct UpcomingRacesCard: View {
    @Environment(\.unitPreference) private var units
    let races: [Race]

    var body: some View {
        if !uniqueRaces.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Upcoming Races")
                    .font(.headline)

                ForEach(uniqueRaces) { race in
                    raceRow(race)
                    if race.id != uniqueRaces.last?.id {
                        Divider()
                            .opacity(0.4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardStyle()
            .accessibilityIdentifier("dashboard.upcomingRacesCard")
        }
    }

    /// Deduplicate by ID in case of CloudKit sync duplicates
    private var uniqueRaces: [Race] {
        var seenIds = Set<UUID>()
        return races.filter { race in
            guard !seenIds.contains(race.id) else { return false }
            seenIds.insert(race.id)
            return true
        }
    }

    private func raceRow(_ race: Race) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(race.priority.badgeColor.gradient)
                .frame(width: 4, height: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(race.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: Theme.Spacing.xs) {
                    Text(UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0))
                    Text("·")
                    Text("\(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) D+")
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(daysUntilText(race.date))
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.primary)
                Text(race.priority.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(race.priority.badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(race.priority.badgeColor.opacity(0.12))
                    .clipShape(Capsule())
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
