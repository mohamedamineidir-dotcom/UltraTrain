import SwiftUI

struct FeatureTourView: View {
    @Environment(\.colorScheme) private var colorScheme
    var onDismiss: () -> Void
    @State private var currentPage = 0
    @State private var showContent = false

    private let pages: [TourPage] = [
        TourPage(
            icon: "chart.bar.fill",
            color: Theme.Colors.warmCoral,
            title: "Your Training Hub",
            description: "Track your fitness trend, weekly volume, and training load from your personalized dashboard.",
            features: ["Fitness & fatigue tracking", "Weekly volume charts", "Plan adherence score"]
        ),
        TourPage(
            icon: "location.fill",
            color: Theme.Colors.success,
            title: "Track Every Step",
            description: "GPS tracking with live pace, elevation profile, and heart rate zones.",
            features: ["Live GPS tracking", "Automatic Strava sync", "Post-run analysis"]
        ),
        TourPage(
            icon: "calendar",
            color: Theme.Colors.primary,
            title: "Your Personalized Plan",
            description: "Periodized training built around your race with smart recovery and adaptive adjustments.",
            features: ["Tailored to your race", "Smart recovery weeks", "Adapts as you train"]
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") { onDismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(Theme.Spacing.md)
                }
            }

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    tourPageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    onDismiss()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Let's Go!")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.Gradients.warmCoralCTA)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(tourBackground)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
        .onChange(of: currentPage) { _, _ in
            showContent = false
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                showContent = true
            }
        }
    }

    private func tourPageView(_ page: TourPage) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Icon with animated glow
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(page.color)
            }
            .shadow(color: page.color.opacity(0.25), radius: 20, y: 6)
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)

            // Title
            Text(page.title)
                .font(.title.bold())
                .foregroundStyle(Theme.Colors.label)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

            // Description
            Text(page.description)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
                .opacity(showContent ? 1 : 0)

            // Feature bullets
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(page.color)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.label)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.top, Theme.Spacing.sm)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 16)

            Spacer()
            Spacer()
        }
    }

    @ViewBuilder
    private var tourBackground: some View {
        Group {
            if colorScheme == .dark {
                Theme.Gradients.premiumBackground
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.96, blue: 0.94),
                        Color(red: 1.0, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct TourPage {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let features: [String]
}
