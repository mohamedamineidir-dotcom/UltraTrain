import SwiftUI

struct WelcomeStepView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 80
    @State private var currentPage = 0

    private let features: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("calendar.badge.clock", "Personalized Training Plans", "Periodized plans built around your A-race with smart recovery weeks", Theme.Colors.primary),
        ("location.fill", "GPS Run Tracking", "Track every run with live pace, elevation, and heart rate zones", Theme.Colors.success),
        ("fork.knife.circle.fill", "Smart Nutrition", "Race-day fueling strategy with gut training reminders", Theme.Colors.warning),
        ("chart.line.uptrend.xyaxis", "Race Predictions", "AI-powered finish time estimates that update as you train", Theme.Colors.info)
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: heroIconSize))
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)

            Text("Welcome to UltraTrain")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Your ultra trail training companion")
                .font(.title3)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            TabView(selection: $currentPage) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeaturePreviewCard(
                        icon: feature.icon,
                        title: feature.title,
                        subtitle: feature.subtitle,
                        color: feature.color
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 220)

            Spacer()
        }
        .padding()
        .task {
            await autoAdvance()
        }
    }

    private func autoAdvance() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage = (currentPage + 1) % features.count
            }
        }
    }
}
