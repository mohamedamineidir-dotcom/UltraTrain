import SwiftUI

struct FeatureTourView: View {
    var onDismiss: () -> Void
    @State private var currentPage = 0
    @ScaledMetric(relativeTo: .largeTitle) private var pageIconSize: CGFloat = 80

    private let pages: [(icon: String, color: Color, title: String, description: String)] = [
        ("chart.bar.fill", Theme.Colors.primary, "Your Training Hub",
         "Track your fitness trend, weekly volume, and training load — all from your personalized dashboard."),
        ("location.fill", Theme.Colors.success, "Track Every Step",
         "GPS tracking with live pace, elevation profile, heart rate zones, and automatic Strava upload."),
        ("calendar", Theme.Colors.info, "Your Personalized Plan",
         "Periodized training built around your A-race with smart recovery weeks and adaptive adjustments.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") { onDismiss() }
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(Theme.Spacing.md)
                        .accessibilityHint("Skips the feature tour and goes to the main app")
                }
            }

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: Theme.Spacing.xl) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: pageIconSize))
                            .foregroundStyle(page.color)
                            .frame(width: 140, height: 140)
                            .background(page.color.opacity(0.12))
                            .clipShape(Circle())
                            .accessibilityHidden(true)

                        Text(page.title)
                            .font(.title.bold())

                        Text(page.description)
                            .font(.body)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)

                        Spacer()
                    }
                    .tag(index)
                    .accessibilityElement(children: .combine)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onDismiss()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Let's Go!")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
            .accessibilityHint(currentPage < pages.count - 1 ? "Shows the next feature" : "Closes the tour and opens the main app")
        }
        .background(Theme.Colors.background)
    }
}
