import SwiftUI

struct TrainingCalendarDayDetail: View {
    @Environment(\.unitPreference) private var units
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let phase: TrainingPhase?
    let sessions: [TrainingSession]
    let runs: [CompletedRun]

    var body: some View {
        NavigationStack {
            List {
                if let phase {
                    Section {
                        PhaseBadge(phase: phase)
                    }
                }

                if !sessions.isEmpty {
                    Section("Planned Sessions") {
                        ForEach(sessions) { session in
                            sessionRow(session)
                        }
                    }
                }

                if !runs.isEmpty {
                    Section("Completed Runs") {
                        ForEach(runs) { run in
                            runRow(run)
                        }
                    }
                }

                if sessions.isEmpty && runs.isEmpty {
                    ContentUnavailableView(
                        "No Activity",
                        systemImage: "calendar.badge.minus",
                        description: Text("Nothing scheduled or recorded for this day.")
                    )
                }
            }
            .navigationTitle(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Session Row

    private func sessionRow(_ session: TrainingSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(session.type.rawValue.camelCaseToWords)
                        .font(.subheadline.bold())

                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.success)
                            .font(.caption)
                    } else if session.isSkipped {
                        Image(systemName: "forward.fill")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .font(.caption)
                    }
                }

                HStack(spacing: Theme.Spacing.sm) {
                    if session.plannedDistanceKm > 0 {
                        Text(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    if session.plannedElevationGainM > 0 {
                        Text(UnitFormatter.formatElevation(session.plannedElevationGainM, unit: units))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }

            Spacer()

            Text(session.intensity.rawValue.capitalized)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(intensityColor(session.intensity).opacity(0.15))
                .clipShape(Capsule())
        }
    }

    // MARK: - Run Row

    private func runRow(_ run: CompletedRun) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Theme.Spacing.sm) {
                Text(UnitFormatter.formatDistance(run.distanceKm, unit: units))
                    .font(.subheadline.bold())

                Text(formatDuration(run.duration))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            HStack(spacing: Theme.Spacing.sm) {
                Text(RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units) + " " + UnitFormatter.paceLabel(units))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                if let hr = run.averageHeartRate {
                    Text("\(hr) bpm")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                if run.elevationGainM > 0 {
                    Text(UnitFormatter.formatElevation(run.elevationGainM, unit: units))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }

    // MARK: - Helpers

    private func intensityColor(_ intensity: Intensity) -> Color {
        switch intensity {
        case .easy: Theme.Colors.success
        case .moderate: Theme.Colors.warning
        case .hard: Theme.Colors.danger
        case .maxEffort: .red
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

// MARK: - String Extension

private extension String {
    var camelCaseToWords: String {
        unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar) && !result.isEmpty {
                return result + " " + String(scalar)
            }
            return result + String(scalar)
        }.capitalized
    }
}
