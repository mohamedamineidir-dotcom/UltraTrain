import SwiftUI

/// Hero header for the Race Day nutrition tab. Gives the athlete race
/// context at a glance: name, distance, elevation gain, and expected finish
/// duration. The gradient + icon row evoke a live race-day feel without
/// being overwhelming.
struct NutritionRaceHeroCard: View {

    let raceName: String
    let raceDate: Date
    let distanceKm: Double
    let elevationGainM: Double
    let estimatedDurationSeconds: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Top row: race name + relative date
            HStack(alignment: .firstTextBaseline) {
                Text(raceName)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.Colors.label)
                    .lineLimit(1)
                Spacer()
                Text(daysUntilText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accentColor)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(Theme.Colors.accentColor.opacity(0.15))
                    )
            }

            // Subtitle: race date
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Divider().padding(.vertical, Theme.Spacing.xs)

            // Stats row
            HStack(spacing: Theme.Spacing.md) {
                heroStat(
                    icon: "ruler",
                    iconColor: .cyan,
                    value: formattedDistance,
                    label: "distance"
                )
                heroStatDivider
                heroStat(
                    icon: "mountain.2.fill",
                    iconColor: .green,
                    value: formattedElevation,
                    label: "elevation"
                )
                heroStatDivider
                heroStat(
                    icon: "clock.fill",
                    iconColor: .orange,
                    value: formattedDuration,
                    label: "expected"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.accentColor.opacity(0.18),
                            Theme.Colors.accentColor.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.accentColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Theme.Colors.accentColor.opacity(0.08), radius: 10, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(raceName), \(formattedDistance), \(formattedElevation) elevation, expected \(formattedDuration)")
    }

    // MARK: - Stat cell

    private func heroStat(
        icon: String,
        iconColor: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private var heroStatDivider: some View {
        Rectangle()
            .fill(Theme.Colors.secondaryLabel.opacity(0.15))
            .frame(width: 1, height: 30)
    }

    // MARK: - Formatting

    private var formattedDistance: String {
        "\(Int(distanceKm)) km"
    }

    private var formattedElevation: String {
        elevationGainM < 50 ? "flat" : "\(Int(elevationGainM)) m D+"
    }

    private var formattedDuration: String {
        let totalMinutes = Int(estimatedDurationSeconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m) min" }
        return String(format: "%dh%02d", h, m)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: raceDate)
    }

    private var daysUntilText: String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: raceDate).day ?? 0
        if days < 0 { return "past" }
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        if days < 30 { return "in \(days)d" }
        let weeks = days / 7
        if weeks < 8 { return "in \(weeks)w" }
        let months = days / 30
        return "in \(months)mo"
    }
}
