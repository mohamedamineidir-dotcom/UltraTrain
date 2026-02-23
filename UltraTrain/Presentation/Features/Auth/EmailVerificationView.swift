import SwiftUI

struct EmailVerificationView: View {
    @State private var viewModel: EmailVerificationViewModel
    private let onVerified: () -> Void
    private let onSkip: () -> Void

    init(authService: any AuthServiceProtocol, onVerified: @escaping () -> Void, onSkip: @escaping () -> Void) {
        _viewModel = State(initialValue: EmailVerificationViewModel(authService: authService))
        self.onVerified = onVerified
        self.onSkip = onSkip
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection

                TextField("6-digit code", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospaced())
                    .padding()
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.verify() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Verify Email")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.code.count != 6)

                resendSection

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .padding()
        }
        .navigationTitle("Verify Email")
        .navigationBarBackButtonHidden()
        .onChange(of: viewModel.isVerified) { _, verified in
            if verified { onVerified() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 50))
                .foregroundStyle(Theme.Colors.primary)

            Text("Check your email")
                .font(.title3.bold())

            Text("We sent a 6-digit verification code to your email address.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var resendSection: some View {
        Group {
            if viewModel.resendCooldown > 0 {
                Text("Resend code in \(viewModel.resendCooldown)s")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                Button {
                    Task { await viewModel.resendCode() }
                } label: {
                    Text("Resend verification code")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.primary)
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}
