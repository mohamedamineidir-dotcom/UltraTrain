import SwiftUI

/// Redesigned hourly-targets card for the Race Day nutrition tab. Carbs per
/// hour is the primary hero metric (modern Jeukendrup / ISSN standard),
/// secondary stats show hydration, sodium, caffeine, and total grams across
/// the race.
struct NutritionTargetsCard: View {

    let carbsPerHour: Int
    let hydrationMlPerHour: Int
    let sodiumMgPerHour: Int
    let totalCaffeineMg: Int
    let totalCarbsGrams: Int
    let estimatedDurationSeconds: TimeInterval
    let gutTrainingSessions: Int

    @State private var showingExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header

            heroCarbs

            secondaryStats

            Divider()

            footer
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.secondaryLabel.opacity(0.12), lineWidth: 1)
        )
        .sheet(isPresented: $showingExplainer) {
            TargetsExplainerSheet()
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Label("Fueling targets", systemImage: "target")
                .font(.headline)
            Spacer()
            Button {
                showingExplainer = true
            } label: {
                Label("Why?", systemImage: "info.circle")
                    .font(.caption.weight(.medium))
                    .labelStyle(.titleAndIcon)
            }
            .accessibilityLabel("Why these targets")
            .accessibilityIdentifier("nutrition.targetsExplainerButton")
        }
    }

    // MARK: - Hero carbs

    private var heroCarbs: some View {
        HStack(alignment: .lastTextBaseline, spacing: Theme.Spacing.sm) {
            Text("\(carbsPerHour)")
                .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accentColor, Theme.Colors.accentColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 0) {
                Text("g / hr")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.Colors.label)
                Text("carbohydrate")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            // Total grams across race as a secondary pill
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalCarbsGrams) g")
                    .font(.subheadline.bold().monospacedDigit())
                Text("race total")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Secondary stats

    private var secondaryStats: some View {
        HStack(spacing: Theme.Spacing.sm) {
            stat(icon: "drop.fill", iconColor: .cyan,
                 value: "\(hydrationMlPerHour)", unit: "ml/h", label: "hydration")
            statDivider
            stat(icon: "cross.vial.fill", iconColor: .mint,
                 value: "\(sodiumMgPerHour)", unit: "mg/h", label: "sodium")
            statDivider
            stat(icon: "bolt.fill", iconColor: totalCaffeineMg > 0 ? .yellow : .gray,
                 value: totalCaffeineMg > 0 ? "\(totalCaffeineMg)" : "—",
                 unit: totalCaffeineMg > 0 ? "mg" : "",
                 label: "caffeine total")
        }
    }

    private func stat(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(iconColor)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.Colors.secondaryLabel.opacity(0.12))
            .frame(width: 1, height: 40)
    }

    // MARK: - Footer (practice reminder + duration)

    private var footer: some View {
        HStack(spacing: Theme.Spacing.md) {
            Label(formattedDuration, systemImage: "timer")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
            if gutTrainingSessions > 0 {
                Label("\(gutTrainingSessions) training runs to practice", systemImage: "figure.run")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.accentColor)
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
    }
}
