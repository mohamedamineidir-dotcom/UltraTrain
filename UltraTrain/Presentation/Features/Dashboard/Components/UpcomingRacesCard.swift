import SwiftUI

struct UpcomingRacesCard: View {
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

            VStack(alignment: .leading, spacing: 2) {
                Text(race.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(String(format: "%.0f km · %.0f m D+", race.distanceKm, race.elevationGainM))
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
