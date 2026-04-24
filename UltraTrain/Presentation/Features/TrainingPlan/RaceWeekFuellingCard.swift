import SwiftUI

/// Race-week carb-loading + hydration + morning-meal card. Rendered on
/// the race session detail so the athlete can glance at the full
/// fuelling plan from the same screen they check their pacing target.
///
/// Built from `RaceFuellingProtocolGenerator` — all values derive from
/// the athlete's weight and the race's estimated duration, so the copy
/// is personalised, not a generic leaflet.
struct RaceWeekFuellingCard: View {
    let athleteWeightKg: Double
    let estimatedRaceDurationSeconds: TimeInterval
    /// Athlete's preferred pre-race meal window captured in the
    /// nutrition onboarding. Nil when onboarding was skipped; the
    /// generator falls back to the 3h default.
    var preRaceMealTiming: PreRaceMealTiming? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var protocolPlan: RaceFuellingProtocolGenerator.FuellingPlan? {
        RaceFuellingProtocolGenerator.build(
            athleteWeightKg: athleteWeightKg,
            estimatedRaceDurationSeconds: estimatedRaceDurationSeconds,
            preRaceMealTiming: preRaceMealTiming
        )
    }

    var body: some View {
        if let plan = protocolPlan {
            content(plan)
        }
    }

    private func content(_ plan: RaceFuellingProtocolGenerator.FuellingPlan) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header
            Text(plan.rationale)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            if !plan.loadingPhases.isEmpty {
                Divider()
                ForEach(Array(plan.loadingPhases.enumerated()), id: \.offset) { _, phase in
                    phaseRow(phase)
                }
            }

            Divider()
            phaseRow(plan.morning)

            Text(plan.during)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(LinearGradient(
                    colors: [
                        NutritionPalette.tint.opacity(colorScheme == .dark ? 0.22 : 0.12),
                        NutritionPalette.tint.opacity(colorScheme == .dark ? 0.06 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.10 : 0.40), location: 0.0),
                        .init(color: Color.clear, location: 0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(NutritionPalette.tint.opacity(0.28), lineWidth: 0.75)
        )
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "fork.knife")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NutritionPalette.tint)
            Text("RACE WEEK FUELLING")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NutritionPalette.tint)
            Spacer()
            Text("\(Int(athleteWeightKg.rounded())) kg")
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundStyle(Theme.Colors.tertiaryLabel)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Theme.Colors.tertiaryLabel.opacity(0.1)))
        }
    }

    private func phaseRow(_ phase: RaceFuellingProtocolGenerator.Phase) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(phase.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Text("\(phase.carbsGrams) g")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(NutritionPalette.tint)
                Text(String(format: "(%.1f g/kg)", phase.carbsPerKg))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            Text(phase.detail)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1)
        }
    }
}
