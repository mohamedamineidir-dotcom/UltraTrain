import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel
    @Environment(\.dismiss) private var dismiss

    init(authService: any AuthServiceProtocol) {
        _viewModel = State(initialValue: ForgotPasswordViewModel(authService: authService))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection

                switch viewModel.step {
                case .enterEmail:
                    emailStepView
                case .enterCode:
                    codeStepView
                }

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password Reset", isPresented: $viewModel.isResetComplete) {
            Button("Sign In") { dismiss() }
        } message: {
            Text("Your password has been reset. You can now sign in with your new password.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 50))
                .foregroundStyle(Theme.Colors.primary)

            Text(viewModel.step == .enterEmail
                ? "Enter your email to receive a reset code"
                : "Enter the 6-digit code and your new password")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var emailStepView: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

            Button {
                Task { await viewModel.requestReset() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Send Reset Code")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.email.isEmpty)
        }
    }

    private var codeStepView: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("6-digit code", text: $viewModel.code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

            SecureField("New Password", text: $viewModel.newPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

            Button {
                Task { await viewModel.resetPassword() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Reset Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.code.isEmpty || viewModel.newPassword.isEmpty)
        }
    }
}
