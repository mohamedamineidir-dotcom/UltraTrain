import SwiftUI

/// Hourly-targets card for the Race Day nutrition tab. Four equal-weight
/// tiles in a 2×2 grid, carbs, hydration, sodium, caffeine, so the
/// athlete sees every per-hour target at a glance without one metric
/// drowning out the others. Race total + expected duration sit quietly
/// in the footer; gut-training practice count surfaces as a soft chip.
///
/// Designed for at-a-glance race-day reading: each tile is a premium
/// glass surface with a single icon, a bold value, a small unit and a
/// label. No decorative clutter competing for the athlete's attention.
struct NutritionTargetsCard: View {

    let carbsPerHour: Int
    let hydrationMlPerHour: Int
    let sodiumMgPerHour: Int
    let totalCaffeineMg: Int
    let totalCarbsGrams: Int
    let estimatedDurationSeconds: TimeInterval
    let gutTrainingSessions: Int

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header
            tileGrid
            footer
        }
        .futuristicGlassStyle(phaseTint: NutritionPalette.tint)
        .sheet(isPresented: $showingExplainer) {
            TargetsExplainerSheet()
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs + 2) {
                Image(systemName: "target")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NutritionPalette.tint)
                Text("FUELING TARGETS")
                    .font(.caption.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(NutritionPalette.tint)
            }
            Spacer()
            Button {
                showingExplainer = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("Why?")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .accessibilityLabel("Why these targets")
            .accessibilityIdentifier("nutrition.targetsExplainerButton")
        }
    }

    // MARK: - Tile grid

    private var tileGrid: some View {
        VStack(spacing: Theme.Spacing.sm + 2) {
            HStack(spacing: Theme.Spacing.sm + 2) {
                tile(
                    icon: "bolt.heart.fill",
                    iconColor: NutritionPalette.tint,
                    value: "\(carbsPerHour)",
                    unit: "g/hr",
                    label: "Carbs",
                    accent: true
                )
                tile(
                    icon: "drop.fill",
                    iconColor: .cyan,
                    value: "\(hydrationMlPerHour)",
                    unit: "ml/hr",
                    label: "Hydration"
                )
            }
            HStack(spacing: Theme.Spacing.sm + 2) {
                tile(
                    icon: "cross.vial.fill",
                    iconColor: .mint,
                    value: "\(sodiumMgPerHour)",
                    unit: "mg/hr",
                    label: "Sodium"
                )
                tile(
                    icon: "bolt.fill",
                    iconColor: totalCaffeineMg > 0 ? .yellow : Theme.Colors.tertiaryLabel,
                    value: totalCaffeineMg > 0 ? "\(totalCaffeineMg)" : "—",
                    unit: totalCaffeineMg > 0 ? "mg total" : "",
                    label: "Caffeine"
                )
            }
        }
    }

    private func tile(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        label: String,
        accent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent ? .white : iconColor)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(
                            accent
                                ? AnyShapeStyle(NutritionPalette.gradient)
                                : AnyShapeStyle(iconColor.opacity(0.20))
                        )
                    )
                Text(LocalizedStringKey(label))
                    .textCase(.uppercase)
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(accent ? NutritionPalette.tint : Theme.Colors.secondaryLabel)
                Spacer(minLength: 0)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        accent
                            ? AnyShapeStyle(LinearGradient(
                                colors: [NutritionPalette.tint, NutritionPalette.deep],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            : AnyShapeStyle(Theme.Colors.label)
                    )
                if !unit.isEmpty {
                    Text(LocalizedStringKey(unit))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(tileFill(accent: accent, iconColor: iconColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    accent
                        ? NutritionPalette.tint.opacity(0.45)
                        : iconColor.opacity(0.22),
                    lineWidth: accent ? 1.0 : 0.6
                )
        )
    }

    /// Tinted tile fill, each metric gets a whisper of its own colour
    /// so the four tiles feel distinct against the glass card behind
    /// them instead of disappearing into a sea of white. Accent tile
    /// (carbs) leans harder into the nutrition green.
    private func tileFill(accent: Bool, iconColor: Color) -> AnyShapeStyle {
        if accent {
            return AnyShapeStyle(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [NutritionPalette.tint.opacity(0.18), NutritionPalette.tint.opacity(0.08)]
                        : [NutritionPalette.tint.opacity(0.12), NutritionPalette.tint.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [iconColor.opacity(0.12), iconColor.opacity(0.04)]
                    : [iconColor.opacity(0.08), iconColor.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Theme.Spacing.md) {
            Label(formattedDuration, systemImage: "timer")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text("·")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
            Text("\(totalCarbsGrams) g total carbs")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            if gutTrainingSessions > 0 {
                Label("\(gutTrainingSessions) runs", systemImage: "figure.run")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NutritionPalette.tint)
                    .padding(.horizontal, Theme.Spacing.xs + 2)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(NutritionPalette.tint.opacity(0.12))
                    )
            }
        }
    }

    private var formattedDuration: String {
        let totalMinutes = Int(estimatedDurationSeconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m) min" }
        return String(format: "%dh%02d", h, m)
    }
}

// MARK: - Explainer sheet

private struct TargetsExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    section(
                        title: String(localized: "ntx.carbs.title", defaultValue: "Carbs per hour"),
                        body: String(localized: "ntx.carbs.body", defaultValue: "Scaled to your race duration. Most runners need 60 to 90 g per hour, from a mix of glucose and fructose to avoid GI issues.")
                    )
                    section(
                        title: String(localized: "ntx.hydration.title", defaultValue: "Hydration"),
                        body: String(localized: "ntx.hydration.body", defaultValue: "Set from your sweat rate, or estimated from your weight and the weather. We aim to replace about 80% of what you lose.")
                    )
                    section(
                        title: String(localized: "ntx.sodium.title", defaultValue: "Sodium"),
                        body: String(localized: "ntx.sodium.body", defaultValue: "Matched to how salty your sweat is. Races over 6 hours apply a 575 mg per liter floor.")
                    )
                    section(
                        title: String(localized: "ntx.caffeine.title", defaultValue: "Caffeine"),
                        body: String(localized: "ntx.caffeine.body", defaultValue: "3 to 6 mg per kg of body weight, tuned to your tolerance. Spread across the race, with night doses for ultras.")
                    )
                    section(
                        title: String(localized: "ntx.why.title", defaultValue: "Why practice this in training?"),
                        body: String(localized: "ntx.why.body", defaultValue: "Your gut can be trained. Start at 40 g per hour, add 10 g every two weeks, and test your full race intake on two long runs before the event.")
                    )
                }
                .padding()
            }
            .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle("Why these targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title).font(.headline)
            Text(try! AttributedString(markdown: body))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(NutritionPalette.tint.opacity(0.14), lineWidth: 0.5)
        )
    }
}
