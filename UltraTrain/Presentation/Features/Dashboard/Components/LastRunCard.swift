import SwiftUI

struct LastRunCard: View {
    @Environment(\.unitPreference) private var units
    let lastRun: CompletedRun?

    var body: some View {
        if let run = lastRun {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header row: title + relative date pill
                HStack {
                    Label("Last Run", systemImage: "figure.run")
                        .font(.headline)
                    Spacer()
                    Text(relativeDateString(run.date))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accentColor)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.Colors.accentColor.opacity(0.12)))
                }

                // Three-column stats with colored icons
                HStack(spacing: Theme.Spacing.sm) {
                    statColumn(
                        icon: "ruler",
                        iconColor: .cyan,
                        value: String(format: "%.1f", UnitFormatter.distanceValue(run.distanceKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units)
                    )
                    statDivider
                    statColumn(
                        icon: "speedometer",
                        iconColor: .orange,
                        value: RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units),
                        unit: "pace"
                    )
                    statDivider
                    statColumn(
                        icon: "clock.fill",
                        iconColor: .green,
                        value: formattedDuration(run.duration),
                        unit: "time"
                    )
                }

                // Tags row
                if run.perceivedFeeling != nil || run.rpe != nil || run.terrainType != nil {
                    HStack(spacing: Theme.Spacing.xs) {
                        if let feeling = run.perceivedFeeling {
                            Text(feelingEmoji(feeling))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                        if let rpe = run.rpe {
                            tagPill(text: "RPE \(rpe)")
                        }
                        if let terrain = run.terrainType {
                            tagPill(text: terrain.rawValue.capitalized)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .futuristicGlassStyle()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription(for: run))
        }
    }

    private func tagPill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Theme.Colors.glassBorder, lineWidth: 0.5))
            )
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.Colors.secondaryLabel.opacity(0.12))
            .frame(width: 1, height: 36)
    }

    private func accessibilityDescription(for run: CompletedRun) -> String {
        let dist = AccessibilityFormatters.distance(run.distanceKm, unit: units)
        let pace = AccessibilityFormatters.pace(
            RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units),
            unit: units
        )
        let dur = AccessibilityFormatters.duration(run.duration)
        let when = relativeDateString(run.date)
        return "Last run, \(when). \(dist), pace \(pace), duration \(dur)"
    }

    private func statColumn(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func relativeDateString(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date.startOfDay, to: Date.now.startOfDay).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        return date.formatted(.dateTime.month().day())
    }

    private func feelingEmoji(_ feeling: PerceivedFeeling) -> String {
        switch feeling {
        case .great: "😀"
        case .good: "🙂"
        case .ok: "😐"
        case .tough: "😤"
        case .terrible: "😫"
        }
    }
}
