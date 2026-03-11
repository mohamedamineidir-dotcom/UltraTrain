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
            .preferredColorScheme(.dark)
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
                Color(red: 0.05, green: 0.04, blue: 0.18),
                Color(red: 0.08, green: 0.06, blue: 0.22),
                Color(red: 0.04, green: 0.09, blue: 0.16)
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
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.warmCoral.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Theme.Colors.warmCoral.opacity(0.2), radius: 24, y: 8)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("UltraTrain")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Train for the trails.\nGo the distance.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                }
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
                Text("·").foregroundStyle(.white.opacity(0.3))
                Link("Terms of Service", destination: URL(string: "https://ultratrain.app/terms")!)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.4))
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
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
    }
}
