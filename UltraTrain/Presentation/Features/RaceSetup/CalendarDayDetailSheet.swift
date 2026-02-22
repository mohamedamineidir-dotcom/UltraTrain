import SwiftUI

struct CalendarDayDetailSheet: View {
    @Environment(\.unitPreference) private var units
    let date: Date
    let phase: TrainingPhase?
    let sessions: [TrainingSession]
    let race: Race?
    let onEditRace: (Race) -> Void
    let onDeleteRace: (UUID) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    dateHeader
                    if let race {
                        raceSection(race)
                    }
                    if !sessions.isEmpty {
                        sessionsSection
                    }
                    if race == nil && sessions.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.headline)
                if let phase {
                    PhaseBadge(phase: phase)
                }
            }
            Spacer()
        }
    }

    // MARK: - Race Section

    private func raceSection(_ race: Race) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Race")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)

            RaceDetailCard(
                race: race,
                onEdit: { onEditRace(race) },
                onDelete: { onDeleteRace(race.id) }
            )
        }
    }

    // MARK: - Sessions Section

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Sessions")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(sessions) { session in
                sessionRow(session)
            }
        }
    }

    private func sessionRow(_ session: TrainingSession) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: session.type.icon)
                .font(.body)
                .foregroundStyle(Theme.Colors.primary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.type.displayName)
                    .font(.subheadline.bold())
                Text("\(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units)) · \(UnitFormatter.formatElevation(session.plannedElevationGainM, unit: units)) D+")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            statusBadge(session)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    @ViewBuilder
    private func statusBadge(_ session: TrainingSession) -> some View {
        if session.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.success)
                .accessibilityLabel("Completed")
        } else if session.isSkipped {
            Image(systemName: "forward.fill")
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityLabel("Skipped")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("Rest Day")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("No sessions or races planned.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}
