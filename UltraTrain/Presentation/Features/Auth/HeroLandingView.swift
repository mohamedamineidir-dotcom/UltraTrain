import SwiftUI

struct HeroLandingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSignIn = false
    /// RR-42: the smooth fade/scale-in this screen now owns, ported over
    /// from the removed WelcomeClubView so the very first screen still
    /// gets that entrance treatment instead of just popping in flat.
    @State private var showContent = false

    let authService: any AuthServiceProtocol
    let referralRepository: any ReferralRepository
    /// RR-41: account creation no longer happens here — "Get Started" goes
    /// straight into the onboarding questionnaire, account creation is a
    /// step near the end of it (see OnboardingView).
    var onGetStarted: () -> Void
    var onSignedIn: (String?, String?) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                content
            }
            .navigationDestination(isPresented: $showSignIn) {
                SignInView(
                    authService: authService,
                    onAuthenticated: onSignedIn
                )
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    showContent = true
                }
            }
        }
    }

    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.04, blue: 0.18),
                        Color(red: 0.08, green: 0.06, blue: 0.22),
                        Color(red: 0.04, green: 0.09, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.95, blue: 1.0),
                        Color(red: 0.97, green: 0.96, blue: 1.0),
                        Color(red: 0.95, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero section
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.warmCoral.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image("RunnerGlyph")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [.white, .white.opacity(0.8)]
                                    : [Theme.Colors.warmCoral, Theme.Colors.warmCoral.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Theme.Colors.warmCoral.opacity(0.2), radius: 24, y: 8)
                .scaleEffect(showContent ? 1 : 0.6)
                .opacity(showContent ? 1 : 0)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("UltraTrain")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Train for the trails.\nGo the distance.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 12)
            }

            Spacer()

            // Feature highlights
            VStack(spacing: Theme.Spacing.md) {
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Personalized training plans")
                featureRow(icon: "fork.knife", text: "Race-day nutrition strategy")
                featureRow(icon: "timer", text: "Finish time predictions")
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 12)

            Spacer()

            // Buttons
            VStack(spacing: Theme.Spacing.md) {
                PrimaryOnboardingButton(title: "Get Started") {
                    onGetStarted()
                }

                Button {
                    showSignIn = true
                } label: {
                    Text("I already have an account")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.warmCoral)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Footer
            HStack(spacing: Theme.Spacing.xs) {
                Link("Privacy Policy", destination: URL(string: "https://ultratrain.app/privacy")!)
                Text("·").foregroundStyle(.tertiary)
                Link("Terms of Service", destination: URL(string: "https://ultratrain.app/terms")!)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(Theme.Colors.warmCoral)
            Text(LocalizedStringKey(text))
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
            Spacer()
        }
    }
}
