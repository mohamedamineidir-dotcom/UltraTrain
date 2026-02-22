import SwiftUI

struct RaceCalendarView: View {
    @Environment(\.unitPreference) private var units
    let plan: TrainingPlan
    let races: [Race]

    private var racesByWeek: [Int: Race] {
        var map: [Int: Race] = [:]
        let allRaceIds = Set([plan.targetRaceId] + plan.intermediateRaceIds)
        let planRaces = races.filter { allRaceIds.contains($0.id) }
        for race in planRaces {
            if let week = plan.weeks.first(where: {
                $0.contains(date: race.date)
            }) {
                map[week.weekNumber] = race
            }
        }
        return map
    }

    private var currentWeekId: UUID? {
        plan.weeks.first { $0.containsToday }?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    headerSection
                    weeksList
                    footerSection
                }
                .padding()
            }
            .onAppear {
                if let id = currentWeekId {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .navigationTitle("Race Calendar")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("\(plan.totalWeeks)-Week Plan")
                .font(.title3.bold())
            phaseLegend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.bottom, Theme.Spacing.sm)
    }

    private var phaseLegend: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(usedPhases, id: \.self) { phase in
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(phase.color)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    Text(phase.displayName)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Training phases: \(usedPhases.map(\.displayName).joined(separator: ", "))")
    }

    private var usedPhases: [TrainingPhase] {
        let phases = Set(plan.weeks.map(\.phase))
        return TrainingPhase.allCases.filter { phases.contains($0) }
    }

    // MARK: - Weeks

    private var weeksList: some View {
        ForEach(Array(plan.weeks.enumerated()), id: \.element.id) { index, week in
            VStack(spacing: 0) {
                if shouldShowMonthHeader(at: index) {
                    monthHeader(for: week.startDate)
                }
                RaceCalendarRow(
                    week: week,
                    race: racesByWeek[week.weekNumber],
                    isCurrentWeek: week.containsToday
                )
                .id(week.id)
            }
        }
    }

    private func shouldShowMonthHeader(at index: Int) -> Bool {
        guard index > 0 else { return true }
        let current = plan.weeks[index].startDate
        let previous = plan.weeks[index - 1].startDate
        let calendar = Calendar.current
        return calendar.component(.month, from: current) != calendar.component(.month, from: previous)
    }

    private func monthHeader(for date: Date) -> some View {
        HStack {
            Text(date.formatted(.dateTime.month(.wide).year()))
                .font(.caption.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let target = races.first(where: { $0.id == plan.targetRaceId }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(Theme.Colors.danger)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(target.name)
                            .font(.subheadline.bold())
                        Text(target.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }

            let totalKm = plan.weeks.reduce(0.0) { $0 + $1.targetVolumeKm }
            let totalElev = plan.weeks.reduce(0.0) { $0 + $1.targetElevationGainM }
            HStack(spacing: Theme.Spacing.md) {
                Label("\(UnitFormatter.formatDistance(totalKm, unit: units, decimals: 0)) total", systemImage: "figure.run")
                Label("\(UnitFormatter.formatElevation(totalElev, unit: units)) D+", systemImage: "mountain.2")
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.top, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}
