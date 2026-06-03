import SwiftUI

/// Welcome-back questionnaire shown when a premium custom plan is restored
/// after a break (race still ahead). Two quick steps decide whether the plan
/// resumes as-is or is re-periodized for detraining. Matches the pre-plan
/// onboarding style (dark, glass cards, coral CTA).
struct ComebackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let weeksAway: Int
    let onSelect: (GapTrainingLevel) -> Void

    @State private var step = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    header

                    if step == 0 {
                        question(String(localized: "comeback.q1",
                                        defaultValue: "While you were away, did you keep training for your race?"))
                        card(
                            icon: "checkmark.seal.fill",
                            accent: Theme.Colors.success,
                            title: String(localized: "comeback.q1.yes", defaultValue: "Yes, I kept training"),
                            subtitle: String(localized: "comeback.q1.yes.sub",
                                             defaultValue: "Pick up your plan where today lands.")
                        ) { choose(.keptTraining) }
                        card(
                            icon: "pause.circle.fill",
                            accent: Theme.Colors.warmCoral,
                            title: String(localized: "comeback.q1.no", defaultValue: "No, I took a break"),
                            subtitle: String(localized: "comeback.q1.no.sub",
                                             defaultValue: "We'll ease you back in.")
                        ) { withAnimation { step = 1 } }
                    } else {
                        question(String(format: String(localized: "comeback.q2",
                                                       defaultValue: "How much running did you do over those ~%d weeks?"), weeksAway))
                        card(
                            icon: "figure.run",
                            accent: Theme.Colors.info,
                            title: String(localized: "comeback.q2.some", defaultValue: "Some easy runs"),
                            subtitle: String(localized: "comeback.q2.some.sub", defaultValue: "Stayed ticking over, no structure.")
                        ) { choose(.someEasy) }
                        card(
                            icon: "figure.walk",
                            accent: Theme.Colors.amberAccent,
                            title: String(localized: "comeback.q2.occasional", defaultValue: "A little, here and there"),
                            subtitle: String(localized: "comeback.q2.occasional.sub", defaultValue: "The odd run.")
                        ) { choose(.occasional) }
                        card(
                            icon: "zzz",
                            accent: Theme.Colors.warmCoral,
                            title: String(localized: "comeback.q2.stopped", defaultValue: "Almost nothing"),
                            subtitle: String(localized: "comeback.q2.stopped.sub", defaultValue: "Pretty much stopped.")
                        ) { choose(.stopped) }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle(Text(String(localized: "comeback.title", defaultValue: "Welcome back")))
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        Text(String(localized: "comeback.header",
                    defaultValue: "Your race plan is still here. So we can pick the prep back up at the right level, a couple of quick questions."))
            .font(.subheadline)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .padding(.horizontal, Theme.Spacing.xs)
    }

    private func question(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.Colors.label)
            .padding(.top, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.xs)
    }

    private func choose(_ level: GapTrainingLevel) {
        onSelect(level)
        dismiss()
    }

    private func card(
        icon: String, accent: Color, title: String, subtitle: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().fill(accent.opacity(0.16))
                    Circle().stroke(accent.opacity(0.4), lineWidth: 1)
                    Image(systemName: icon).font(.title3).foregroundStyle(accent)
                }
                .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(Theme.Colors.label)
                    Text(subtitle).font(.caption).foregroundStyle(Theme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .futuristicGlassStyle(phaseTint: accent)
        }
        .buttonStyle(.plain)
    }
}
