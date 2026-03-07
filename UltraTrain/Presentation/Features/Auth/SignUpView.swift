import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @State private var viewModel: SignUpViewModel
    @State private var showEmailVerification = false
    @State private var showWelcomeClub = false

    let referralRepository: any ReferralRepository
    var onAuthenticated: (Bool, String?) -> Void

    init(
        authService: any AuthServiceProtocol,
        referralRepository: any ReferralRepository,
        onAuthenticated: @escaping (Bool, String?) -> Void
    ) {
        self.referralRepository = referralRepository
        self.onAuthenticated = onAuthenticated
        _viewModel = State(initialValue: SignUpViewModel(
            authService: authService,
            referralRepository: referralRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                formSection
                createAccountButton
                OrDividerView()
                socialAuthSection
                termsSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated {
                if viewModel.isNewUser {
                    showWelcomeClub = true
                } else {
                    onAuthenticated(false, nil)
                }
            }
        }
        .navigationDestination(isPresented: $showWelcomeClub) {
            WelcomeClubView(
                firstName: viewModel.authenticatedFirstName ?? "",
                referralRepository: referralRepository,
                onContinue: {
                    onAuthenticated(true, viewModel.authenticatedFirstName)
                }
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Join the trail community")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var formSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            OnboardingTextField(
                placeholder: "First Name",
                text: $viewModel.firstName,
                textContentType: .givenName,
                autocapitalization: .words
            )

            OnboardingTextField(
                placeholder: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            OnboardingTextField(
                placeholder: "Password (8+ characters)",
                text: $viewModel.password,
                isSecure: true,
                textContentType: .newPassword
            )
        }
    }

    private var createAccountButton: some View {
        PrimaryOnboardingButton(
            title: "Create Account",
            isLoading: viewModel.isLoading,
            isEnabled: !viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty
                && !viewModel.email.isEmpty
                && viewModel.password.count >= 8
        ) {
            Task { await viewModel.createAccount() }
        }
    }

    private var socialAuthSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SocialAuthButton(provider: .apple, isLoading: viewModel.isAppleLoading) {
                signInWithApple()
            }
            SocialAuthButton(provider: .google, isLoading: viewModel.isGoogleLoading) {
                Task {
                    do {
                        let idToken = try await GoogleSignInCoordinator.signIn()
                        await viewModel.signInWithGoogle(idToken: idToken)
                    } catch {
                        viewModel.error = error.localizedDescription
                    }
                }
            }
            SocialAuthButton(provider: .strava, isLoading: viewModel.isStravaLoading) {
                // Strava sign-in uses existing OAuth flow
            }
        }
    }

    private var termsSection: some View {
        Text("By creating an account, you agree to our [Terms of Service](https://ultratrain.app/terms) and [Privacy Policy](https://ultratrain.app/privacy).")
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .multilineTextAlignment(.center)
            .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Apple Sign-In

    private func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let coordinator = AppleSignInCoordinator { result in
            Task {
                switch result {
                case .success(let credential):
                    await viewModel.signInWithApple(
                        identityToken: credential.identityToken,
                        firstName: credential.firstName,
                        lastName: credential.lastName
                    )
                case .failure(let error):
                    await MainActor.run {
                        viewModel.error = error.localizedDescription
                    }
                }
            }
        }
        controller.delegate = coordinator
        controller.performRequests()
        // Keep coordinator alive
        AppleSignInCoordinator.current = coordinator
    }
}
