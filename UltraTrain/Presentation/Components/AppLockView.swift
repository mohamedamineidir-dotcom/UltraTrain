import SwiftUI
import os

struct AppLockView: View {
    let biometricService: any BiometricAuthServiceProtocol
    let onUnlocked: () -> Void

    @State private var isAuthenticating = false
    @State private var authError: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: biometricIconName)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Theme.Colors.primary)
                .accessibilityHidden(true)

            Text("UltraTrain is Locked")
                .font(.title2.bold())

            Text("Authenticate to access your training data.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)

            if let authError {
                Text(authError)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.danger)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await authenticate() }
            } label: {
                Label(biometricButtonLabel, systemImage: biometricIconName)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, Theme.Spacing.xl)
            .disabled(isAuthenticating)

            Spacer()
        }
        .padding()
        .task { await authenticate() }
    }

    private var biometricIconName: String {
        switch biometricService.availableBiometricType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .none: "lock.fill"
        }
    }

    private var biometricButtonLabel: String {
        switch biometricService.availableBiometricType {
        case .faceID: "Unlock with Face ID"
        case .touchID: "Unlock with Touch ID"
        case .none: "Unlock"
        }
    }

    private func authenticate() async {
        isAuthenticating = true
        authError = nil
        do {
            let success = try await biometricService.authenticate(
                reason: "Unlock UltraTrain to access your training data"
            )
            if success {
                onUnlocked()
            } else {
                authError = "Authentication failed. Please try again."
            }
        } catch {
            authError = error.localizedDescription
            Logger.biometric.error("Lock screen auth failed: \(error)")
        }
        isAuthenticating = false
    }
}
