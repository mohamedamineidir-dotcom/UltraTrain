import SwiftUI

/// Hourly-targets card for the Race Day nutrition tab. Four equal-weight
/// tiles in a 2×2 grid — carbs, hydration, sodium, caffeine — so the
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
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent ? .white : iconColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            accent
                                ? AnyShapeStyle(NutritionPalette.gradient)
                                : AnyShapeStyle(iconColor.opacity(0.18))
                        )
                    )
                Spacer()
                Text(label.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
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
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.05)
                      : Color.white.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(
                    accent
                        ? NutritionPalette.tint.opacity(0.35)
                        : iconColor.opacity(0.18),
                    lineWidth: accent ? 1.0 : 0.5
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
                        title: "Carbs per hour",
                        body: "Modern endurance research (Jeukendrup, ISSN) prescribes carbohydrate intake in grams per hour, scaled to **expected race duration**. A 4-hour marathon needs ~60–90 g/h; a 12-hour ultra needs 60–90 g/h sustained via mixed glucose + fructose. This is the single biggest driver of performance and GI outcomes."
                    )
                    section(
                        title: "Hydration",
                        body: "Derived from your sweat rate if you've measured it, otherwise from body weight + temperature + humidity. We aim to replace ~80% of fluid loss — over-drinking risks hyponatremia (ISSN 2019)."
                    )
                    section(
                        title: "Sodium",
                        body: "Calculated as **mg per liter of sweat** matched to your composition (heavy salty sweater vs average). Races over 6 h apply the ISSN 575 mg/L floor to prevent hyponatremia."
                    )
                    section(
                        title: "Caffeine",
                        body: "Race-day dose from ISSN's 3–6 mg/kg range, adjusted for your sensitivity and habitual intake. Split across the race with a front, mid, and 3/4 dose for marathons, and back-loaded toward night hours for ultras."
                    )
                    section(
                        title: "Why practice this in training?",
                        body: "The gut is a trainable organ. Start around 40 g/h and add ~10 g/h every 2 weeks until race-day target feels comfortable. Two long runs at your target rate (8–12 weeks before race) dramatically improve absorption."
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
