import SwiftUI

/// Free-tier plan picker: two fixed 12-week scenarios (comeback / 5K).
/// Shown instead of the custom-race options sheet for free users, with an
/// upgrade CTA for athletes who want a plan built around their own race.
struct PlanScenarioPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(PremiumGate.self) private var gate: PremiumGate?

    let onSelect: (FreePlanScenario) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text(String(localized: "scenario.header",
                                defaultValue: "Pick a free 12-week plan, personalized to your level. Upgrade anytime to train for your own race."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, Theme.Spacing.xs)

                    scenarioCard(
                        .comeback,
                        icon: "figure.walk",
                        accent: Theme.Colors.info,
                        title: String(localized: "scenario.comeback.title", defaultValue: "Back to running"),
                        subtitle: String(localized: "scenario.comeback.subtitle",
                                         defaultValue: "Rebuild your aerobic base and get back in shape, at your pace.")
                    )

                    scenarioCard(
                        .fiveK,
                        icon: "flag.checkered",
                        accent: Theme.Colors.warmCoral,
                        title: String(localized: "scenario.fiveK.title", defaultValue: "Prepare a 5K"),
                        subtitle: String(localized: "scenario.fiveK.subtitle",
                                         defaultValue: "Build speed and endurance for a strong 5K.")
                    )

                    Button {
                        dismiss()
                        gate?.presentPaywall()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill").font(.caption)
                            Text(String(localized: "scenario.upgrade.cta",
                                        defaultValue: "Train for your own race with Premium"))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Theme.Colors.goldAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                    .padding(.top, Theme.Spacing.xs)
                }
                .padding(Theme.Spacing.md)
            }
            .background(
                Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea()
            )
            .navigationTitle(Text(String(localized: "scenario.title", defaultValue: "Choose your plan")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) { dismiss() }
                }
            }
        }
    }

    private func scenarioCard(
        _ scenario: FreePlanScenario,
        icon: String,
        accent: Color,
        title: String,
        subtitle: String
    ) -> some View {
        Button {
            onSelect(scenario)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().fill(accent.opacity(0.16))
                    Circle().stroke(accent.opacity(0.4), lineWidth: 1)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(accent)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.label)
                        Text(String(localized: "scenario.weeks", defaultValue: "12 weeks"))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accent.opacity(0.15)))
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .futuristicGlassStyle(phaseTint: accent)
        }
        .buttonStyle(.plain)
    }
}
