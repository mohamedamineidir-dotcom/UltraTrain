import SwiftUI

struct UpcomingRacesCard: View {
    @Environment(\.unitPreference) private var units
    let races: [Race]
    /// Fired when the athlete taps a race row. Used by the dashboard
    /// to push `FinishEstimationView` for that race so the predictor
    /// + evolution chart are one tap away from the home screen, same
    /// as in the Profile section.
    var onTapRace: ((Race) -> Void)? = nil

    var body: some View {
        if !uniqueRaces.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Upcoming Races", systemImage: "flag.checkered")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.primary)

                ForEach(uniqueRaces) { race in
                    if let onTapRace {
                        Button {
                            onTapRace(race)
                        } label: {
                            raceRow(race, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        raceRow(race, showsChevron: false)
                    }
                    if race.id != uniqueRaces.last?.id {
                        Divider()
                            .opacity(0.4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .futuristicGlassStyle(phaseTint: Theme.Colors.primary)
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

    private func raceRow(_ race: Race, showsChevron: Bool) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(race.priority.badgeColor.gradient)
                .frame(width: 4, height: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(race.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.label)
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

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(race.name), \(race.priority.displayName) race. \(UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0)), \(UnitFormatter.formatElevation(race.elevationGainM, unit: units)) elevation gain. \(daysUntilText(race.date))")
        .accessibilityHint(showsChevron ? "Opens the finish-time predictor for this race" : "")
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: date.startOfDay).day ?? 0
        if days == 0 { return String(localized: "Today", defaultValue: "Today") }
        if days == 1 { return String(localized: "race.daysUntil.tomorrow", defaultValue: "Tomorrow") }
        if days < 7 {
            return String(format: String(localized: "race.daysUntil.inDays", defaultValue: "In %lld days"), days)
        }
        let weeks = days / 7
        if weeks == 1 { return String(localized: "race.daysUntil.inOneWeek", defaultValue: "In 1 week") }
        return String(format: String(localized: "race.daysUntil.inWeeks", defaultValue: "In %lld weeks"), weeks)
    }
}
