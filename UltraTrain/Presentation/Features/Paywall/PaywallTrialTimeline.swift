import SwiftUI

/// Three-step reassurance strip: full access today, reminder before
/// billing, cancel anytime. Trimmed from the original four steps because
/// the explicit "Day 7 — billing starts" line read as a charge warning
/// sitting right above the CTA, which kills momentum. The cancel
/// freedom is absorbed into the last step instead.
struct PaywallTrialTimeline: View {
    private struct Step {
        let icon: String
        let tint: Color
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
    }

    private let steps: [Step] = [
        Step(icon: "bolt.circle.fill",
             tint: Theme.Colors.warmCoral,
             title: "paywall.step.today",
             subtitle: "paywall.step.todayDetail"),
        Step(icon: "bell.circle.fill",
             tint: Theme.Colors.amberAccent,
             title: "paywall.step.reminder",
             subtitle: "paywall.step.reminderDetail"),
        Step(icon: "lock.open.fill",
             tint: Theme.Colors.success,
             title: "paywall.step.cancelAnytime",
             subtitle: "paywall.step.cancelAnytimeDetail")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("paywall.trialTitle")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, Theme.Spacing.md)

            ForEach(steps.indices, id: \.self) { index in
                row(steps[index], isLast: index == steps.count - 1)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private func row(_ step: Step, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm + 2) {
            VStack(spacing: 0) {
                Image(systemName: step.icon)
                    .font(.title3)
                    .foregroundStyle(step.tint)
                    .shadow(color: step.tint.opacity(0.45), radius: 6)
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    step.tint.opacity(0.5),
                                    Color.primary.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 28)
                }
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(step.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : Theme.Spacing.sm)
        }
    }
}
