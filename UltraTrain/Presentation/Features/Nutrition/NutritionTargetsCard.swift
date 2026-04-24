import SwiftUI

/// Hourly-targets card for the Race Day nutrition tab. Futuristic-glass
/// treatment with nutrition-domain green tint. Carbs per hour is the
/// primary hero metric (Jeukendrup / ISSN standard); hydration, sodium,
/// and caffeine render as equal-weight tiles below. Total race grams
/// sit as a quiet secondary line under the hero so the athlete has the
/// bigger picture without it competing for attention.
///
/// Designed to read clearly during an ultra: generous line-height, bold
/// numerals, no decorative clutter, high-contrast text.
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
            heroCarbs
            secondaryTiles
            Divider().opacity(0.5)
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

    // MARK: - Hero carbs

    private var heroCarbs: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Text("\(carbsPerHour)")
                    .font(.system(size: 68, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NutritionPalette.tint, NutritionPalette.deep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: NutritionPalette.tint.opacity(0.25), radius: 12, y: 2)
                VStack(alignment: .leading, spacing: 0) {
                    Text("g / hr")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.Colors.label)
                    Text("carbohydrate")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: Theme.Spacing.xs + 2) {
                Text("\(totalCarbsGrams) g total")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("across the race")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
        }
    }

    // MARK: - Secondary tiles

    private var secondaryTiles: some View {
        HStack(spacing: Theme.Spacing.sm) {
            targetTile(
                icon: "drop.fill",
                iconColor: .cyan,
                value: "\(hydrationMlPerHour)",
                unit: "ml/h",
                label: "Hydration"
            )
            targetTile(
                icon: "cross.vial.fill",
                iconColor: .mint,
                value: "\(sodiumMgPerHour)",
                unit: "mg/h",
                label: "Sodium"
            )
            targetTile(
                icon: "bolt.fill",
                iconColor: totalCaffeineMg > 0 ? .yellow : Theme.Colors.tertiaryLabel,
                value: totalCaffeineMg > 0 ? "\(totalCaffeineMg)" : "—",
                unit: totalCaffeineMg > 0 ? "mg" : "",
                label: "Caffeine"
            )
        }
    }

    private func targetTile(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(spacing: Theme.Spacing.xs + 2) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconColor)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.black.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(iconColor.opacity(0.14), lineWidth: 0.5)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Theme.Spacing.md) {
            Label(formattedDuration, systemImage: "timer")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            if gutTrainingSessions > 0 {
                Label("\(gutTrainingSessions) gut-training runs", systemImage: "figure.run")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(NutritionPalette.tint)
            }
        }
    }

    private var formattedDuration: String {
        let totalMinutes = Int(estimatedDurationSeconds / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m) min estimated" }
        return String(format: "%dh%02d estimated", h, m)
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
