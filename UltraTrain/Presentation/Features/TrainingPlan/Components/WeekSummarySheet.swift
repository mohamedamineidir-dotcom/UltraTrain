import SwiftUI

struct WeekSummarySheet: View {
    @Environment(\.unitPreference) private var units
    @Environment(\.dismiss) private var dismiss
    let point: WeekChartDataPoint
    let week: TrainingWeek?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    headerSection
                    metricsSection
                    if let week {
                        sessionsSection(week)
                        adherenceSection(week)
                    }
                }
                .padding()
            }
            .navigationTitle("Week \(point.weekNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(phaseColor)
                .frame(width: 10, height: 10)
            Text("Week \(point.weekNumber)")
                .font(.title2.bold())
            Text("—")
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(point.phase.displayName)
                .font(.title3)
                .foregroundStyle(phaseColor)
        }
    }

    // MARK: - Metrics (Duration, Elevation, Distance)

    private var metricsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            metricBar(
                label: "Duration",
                icon: "clock",
                planned: formatDuration(point.plannedDurationSeconds),
                completed: point.completedDurationSeconds > 0 ? formatDuration(point.completedDurationSeconds) : nil,
                fraction: safeFraction(point.completedDurationSeconds, point.plannedDurationSeconds)
            )
            metricBar(
                label: "Elevation",
                icon: "mountain.2.fill",
                planned: UnitFormatter.formatElevation(point.plannedElevationM, unit: units),
                completed: point.completedElevationM > 0 ? UnitFormatter.formatElevation(point.completedElevationM, unit: units) : nil,
                fraction: safeFraction(point.completedElevationM, point.plannedElevationM)
            )
            if point.completedDistanceKm > 0 {
                metricBar(
                    label: "Distance",
                    icon: "figure.run",
                    planned: nil,
                    completed: UnitFormatter.formatDistance(point.completedDistanceKm, unit: units),
                    fraction: nil
                )
            }
        }
        .appCardStyle()
    }

    private func metricBar(
        label: String,
        icon: String,
        planned: String?,
        completed: String?,
        fraction: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                if let completed, let planned {
                    Text("\(completed) / \(planned)")
                        .font(.subheadline.monospacedDigit().weight(.medium))
                } else if let completed {
                    Text(completed)
                        .font(.subheadline.monospacedDigit().weight(.medium))
                } else if let planned {
                    Text(planned)
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            if let fraction {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.Colors.secondaryLabel.opacity(0.1))
                        Capsule()
                            .fill(phaseColor)
                            .frame(width: geo.size.width * min(fraction, 1.0))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Sessions List

    private func sessionsSection(_ week: TrainingWeek) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Sessions")
                .font(.headline)

            ForEach(week.sessions) { session in
                HStack(spacing: Theme.Spacing.sm) {
                    Text(session.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(width: 30, alignment: .leading)

                    Image(systemName: session.type.icon)
                        .font(.caption2)
                        .foregroundStyle(session.type == .rest ? Theme.Colors.secondaryLabel : session.intensity.color)
                        .frame(width: 16)

                    Text(session.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(session.type == .rest ? Theme.Colors.secondaryLabel : Theme.Colors.label)

                    Spacer()

                    if session.plannedDuration > 0 {
                        Text(formatDuration(session.plannedDuration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.success)
                    } else if session.isSkipped {
                        Image(systemName: "forward.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 2)

                if session.id != week.sessions.last?.id {
                    Divider()
                }
            }
        }
        .appCardStyle()
    }

    // MARK: - Adherence

    private func adherenceSection(_ week: TrainingWeek) -> some View {
        let active = week.sessions.filter { $0.type != .rest && !$0.isSkipped }
        let completed = active.filter(\.isCompleted)
        let keySessions = active.filter(\.isKeySession)
        let keyDone = keySessions.filter(\.isCompleted)

        return HStack(spacing: Theme.Spacing.lg) {
            adherenceStat(
                value: active.isEmpty ? "—" : "\(Int(Double(completed.count) / Double(active.count) * 100))%",
                label: "Adherence"
            )
            adherenceStat(
                value: keySessions.isEmpty ? "—" : "\(keyDone.count)/\(keySessions.count)",
                label: "Key sessions"
            )
        }
        .frame(maxWidth: .infinity)
        .appCardStyle()
    }

    private func adherenceStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Helpers

    private var phaseColor: Color {
        point.phase.color
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let mins = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", mins))"
        }
        return "\(mins)min"
    }

    private func safeFraction(_ completed: Double, _ planned: Double) -> Double {
        guard planned > 0 else { return 0 }
        return completed / planned
    }
}
