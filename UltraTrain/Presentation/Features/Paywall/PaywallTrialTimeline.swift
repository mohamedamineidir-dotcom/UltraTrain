import SwiftUI

struct PaywallTrialTimeline: View {
    private let steps: [(icon: String, iconColor: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey)] = [
        ("checkmark.circle.fill", Theme.Colors.goldAccent,
         "paywall.step.program", "paywall.step.programDone"),
        ("bolt.circle.fill", Theme.Colors.warmCoral,
         "paywall.step.today", "paywall.step.todayDetail"),
        ("bell.circle.fill", Theme.Colors.amberAccent,
         "paywall.step.reminder", "paywall.step.reminderDetail"),
        ("creditcard.circle.fill", .white.opacity(0.6),
         "paywall.step.billing", "paywall.step.billingDetail")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("paywall.trialTitle")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, Theme.Spacing.md)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    VStack(spacing: 0) {
                        Image(systemName: step.icon)
                            .font(.title3)
                            .foregroundStyle(step.iconColor)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 2, height: 32)
                        }
                    }
                    .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(step.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, index < steps.count - 1 ? Theme.Spacing.sm : 0)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}
