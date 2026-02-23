import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var showVerification = false
    private let authService: any AuthServiceProtocol
    private let onAuthenticated: () -> Void

    init(authService: any AuthServiceProtocol, onAuthenticated: @escaping () -> Void) {
        self.authService = authService
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection

                    VStack(spacing: Theme.Spacing.md) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(viewModel.isRegistering ? .newPassword : .password)
                            .padding()
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    }

                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.danger)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(viewModel.isRegistering ? "Create Account" : "Sign In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)

                    Button {
                        viewModel.isRegistering.toggle()
                        viewModel.error = nil
                    } label: {
                        Text(viewModel.isRegistering
                            ? "Already have an account? Sign In"
                            : "Don't have an account? Create one")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.primary)
                    }

                    if !viewModel.isRegistering {
                        NavigationLink {
                            ForgotPasswordView(authService: authService)
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(viewModel.isRegistering ? "Create Account" : "Sign In")
            .onChange(of: viewModel.isAuthenticated) { _, newValue in
                if newValue {
                    if viewModel.didRegister {
                        showVerification = true
                    } else {
                        onAuthenticated()
                    }
                }
            }
            .navigationDestination(isPresented: $showVerification) {
                EmailVerificationView(
                    authService: authService,
                    onVerified: { onAuthenticated() },
                    onSkip: { onAuthenticated() }
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.primary)

            Text("UltraTrain")
                .font(.largeTitle.bold())

            Text("Sync your training across devices")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}
