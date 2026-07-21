import SwiftUI

/// Three-step reassurance strip explaining what subscribing actually gets
/// you and how easy it is to walk away — fills the space the free-trial
/// timeline used to occupy, without implying there's a trial.
struct PaywallValueSection: View {
    private struct Step {
        let icon: String
        let tint: Color
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
    }

    private let steps: [Step] = [
        Step(icon: "bolt.circle.fill",
             tint: Theme.Colors.warmCoral,
             title: "paywall.value.step.instant",
             subtitle: "paywall.value.step.instantDetail"),
        Step(icon: "figure.run.circle.fill",
             tint: Theme.Colors.amberAccent,
             title: "paywall.value.step.adaptive",
             subtitle: "paywall.value.step.adaptiveDetail"),
        Step(icon: "lock.open.fill",
             tint: Theme.Colors.success,
             title: "paywall.value.step.cancel",
             subtitle: "paywall.value.step.cancelDetail")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("paywall.value.title")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, Theme.Spacing.md)

            ForEach(steps.indices, id: \.self) { index in
                row(steps[index], isLast: index == steps.count - 1)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.ultraThinMaterial)
                .opacity(0.55)
        )
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
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
