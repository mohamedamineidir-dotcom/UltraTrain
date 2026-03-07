import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var viewModel: SignInViewModel
    @State private var showForgotPassword = false

    var onAuthenticated: () -> Void

    init(authService: any AuthServiceProtocol, onAuthenticated: @escaping () -> Void) {
        self.onAuthenticated = onAuthenticated
        _viewModel = State(initialValue: SignInViewModel(authService: authService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                formSection
                signInButton
                forgotPasswordLink
                OrDividerView()
                socialAuthSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated { onAuthenticated() }
        }
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView(authService: viewModel.authService)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Welcome back, runner")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var formSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            OnboardingTextField(
                placeholder: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            OnboardingTextField(
                placeholder: "Password",
                text: $viewModel.password,
                isSecure: true,
                textContentType: .password
            )
        }
    }

    private var signInButton: some View {
        PrimaryOnboardingButton(
            title: "Sign In",
            isLoading: viewModel.isLoading,
            isEnabled: !viewModel.email.isEmpty && !viewModel.password.isEmpty
        ) {
            Task { await viewModel.signIn() }
        }
    }

    private var forgotPasswordLink: some View {
        Button("Forgot password?") {
            showForgotPassword = true
        }
        .font(.subheadline)
        .foregroundStyle(Color.accentColor)
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
                        await viewModel.handleGoogleSignIn(idToken: idToken)
                    } catch {
                        viewModel.error = error.localizedDescription
                    }
                }
            }
            SocialAuthButton(provider: .strava, isLoading: viewModel.isStravaLoading) {
                // Strava sign-in
            }
        }
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
                    await viewModel.handleAppleSignIn(
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
        AppleSignInCoordinator.current = coordinator
    }
}
