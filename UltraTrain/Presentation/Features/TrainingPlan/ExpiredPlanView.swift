import SwiftUI

/// Shown on the Plan tab when the active plan's window has fully passed,
/// e.g. the athlete paused/cancelled and came back after the race they were
/// preparing for has gone by. A finished plan can't just resume, they set a
/// fresh goal.
struct ExpiredPlanView: View {
    @Environment(\.colorScheme) private var colorScheme

    let isScenario: Bool
    let primaryTitle: String
    let onPrimary: () -> Void
    var secondaryTitle: String?
    var onSecondary: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.warmCoral.opacity(0.16))
                            .frame(width: 64, height: 64)
                        Image(systemName: "flag.checkered")
                            .font(.title)
                            .foregroundStyle(Theme.Colors.warmCoral)
                    }

                    Text(isScenario
                         ? String(localized: "expiredPlan.scenario.title", defaultValue: "Plan complete")
                         : String(localized: "expiredPlan.custom.title", defaultValue: "Your race has passed"))
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text(isScenario
                         ? String(localized: "expiredPlan.scenario.body",
                                   defaultValue: "Your 12-week plan has run its course. Ready for the next one?")
                         : String(localized: "expiredPlan.custom.body",
                                   defaultValue: "The race date for this plan has gone by. Set up a new goal to start a fresh plan, your past training stays in your history."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .futuristicGlassStyle(phaseTint: Theme.Colors.warmCoral)

                Button(action: onPrimary) {
                    Text(primaryTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Capsule().fill(Theme.Gradients.warmCoralCTA))
                        .shadow(color: Theme.Colors.warmCoral.opacity(0.35), radius: 8, y: 3)
                }
                .accessibilityIdentifier("expiredPlan.primaryButton")

                if let secondaryTitle, let onSecondary {
                    Button(action: onSecondary) {
                        Text(secondaryTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.goldAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .padding(.top, Theme.Spacing.xl)
        }
    }
}
