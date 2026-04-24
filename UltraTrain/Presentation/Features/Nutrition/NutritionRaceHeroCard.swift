import SwiftUI

/// Hero header for the Race Day nutrition tab. Futuristic-glass treatment
/// with the nutrition-domain green tint — race context at a glance:
/// name, countdown pill, distance, elevation, expected finish time.
///
/// Designed to read clearly during an ultra: generous spacing, bold
/// numerals, high contrast against the futuristic background behind it.
struct NutritionRaceHeroCard: View {

    let raceName: String
    let raceDate: Date
    let distanceKm: Double
    let elevationGainM: Double
    let estimatedDurationSeconds: TimeInterval

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            topRow
            statsRow
        }
        .futuristicGlassStyle(phaseTint: NutritionPalette.tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(raceName), \(formattedDistance), \(formattedElevation) elevation, expected \(formattedDuration)")
    }

    // MARK: - Top row

    private var topRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("RACE DAY")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(NutritionPalette.tint)
                Text(raceName)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.Colors.label)
                    .lineLimit(2)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            countdownBadge
        }
    }

    private var countdownBadge: some View {
        VStack(spacing: 0) {
            Text(countdownValue)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(countdownUnit)
                .font(.caption2.weight(.semibold))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, Theme.Spacing.sm + 2)
        .padding(.vertical, Theme.Spacing.xs + 2)
        .frame(minWidth: 56)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(NutritionPalette.gradient)
        )
        .shadow(color: NutritionPalette.tint.opacity(0.35), radius: 8, y: 4)
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            statTile(
                icon: "ruler",
                value: formattedDistance,
                label: "distance"
            )
            statTile(
                icon: "mountain.2.fill",
                value: formattedElevation,
                label: "elevation"
            )
            statTile(
                icon: "clock.fill",
                value: formattedDuration,
                label: "expected"
            )
        }
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(NutritionPalette.tint)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xs + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.black.opacity(0.025))
        )
    }

    // MARK: - Formatting

    private var formattedDistance: String { "\(Int(distanceKm)) km" }

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

    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: raceDate)).day ?? 0
    }

    private var countdownValue: String {
        let d = daysUntil
        if d < 0 { return "—" }
        if d == 0 { return "0" }
        if d < 30 { return "\(d)" }
        if d < 365 { return "\(d / 7)" }
        return "\(d / 30)"
    }

    private var countdownUnit: String {
        let d = daysUntil
        if d < 0 { return "PAST" }
        if d == 0 { return "TODAY" }
        if d == 1 { return "DAY" }
        if d < 30 { return "DAYS" }
        if d < 365 { return d / 7 == 1 ? "WEEK" : "WEEKS" }
        return d / 30 == 1 ? "MONTH" : "MONTHS"
    }
}
