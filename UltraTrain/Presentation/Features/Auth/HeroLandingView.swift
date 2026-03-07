import SwiftUI

struct HeroLandingView: View {
    @State private var showSignUp = false
    @State private var showSignIn = false

    let authService: any AuthServiceProtocol
    let referralRepository: any ReferralRepository
    var onAuthenticated: (Bool, String?) -> Void // (isNewUser, firstName)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                content
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView(
                    authService: authService,
                    referralRepository: referralRepository,
                    onAuthenticated: onAuthenticated
                )
            }
            .navigationDestination(isPresented: $showSignIn) {
                SignInView(
                    authService: authService,
                    onAuthenticated: { onAuthenticated(false, nil) }
                )
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.Colors.heroGradientTop,
                Theme.Colors.heroGradientBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero section
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.9))

                Text("UltraTrain")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Train for the trails.\nGo the distance.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Feature highlights
            VStack(spacing: Theme.Spacing.md) {
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Personalized training plans")
                featureRow(icon: "fork.knife", text: "Race-day nutrition strategy")
                featureRow(icon: "timer", text: "Finish time predictions")
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            // Buttons
            VStack(spacing: Theme.Spacing.sm) {
                PrimaryOnboardingButton(title: "Get Started") {
                    showSignUp = true
                }

                SecondaryOnboardingButton(title: "I already have an account") {
                    showSignIn = true
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Footer
            HStack(spacing: Theme.Spacing.xs) {
                Link("Privacy Policy", destination: URL(string: "https://ultratrain.app/privacy")!)
                Text("·").foregroundStyle(.white.opacity(0.5))
                Link("Terms of Service", destination: URL(string: "https://ultratrain.app/terms")!)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(.white.opacity(0.9))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }
}
