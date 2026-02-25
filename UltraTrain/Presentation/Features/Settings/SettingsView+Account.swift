import SwiftUI

// MARK: - Account & About Sections

extension SettingsView {
    // MARK: - Account Section

    var accountSection: some View {
        Section("Account") {
            Button {
                viewModel.showingChangePassword = true
            } label: {
                Label("Change Password", systemImage: "key")
            }
            .accessibilityHint("Change your account password")

            Button(role: .destructive) {
                viewModel.showingLogoutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .accessibilityHint("Signs out of your UltraTrain account")

            Button(role: .destructive) {
                viewModel.showingDeleteAccountConfirmation = true
            } label: {
                if viewModel.isDeletingAccount {
                    ProgressView()
                } else {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                }
            }
            .disabled(viewModel.isDeletingAccount)
            .accessibilityIdentifier("settings.deleteAccountButton")
            .accessibilityHint("Permanently deletes your account and all data from the server")
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $viewModel.showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await viewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local training data will remain on this device.")
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $viewModel.showingDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data from the server. This action cannot be undone.")
        }
        .onChange(of: viewModel.didLogout) { _, didLogout in
            if didLogout { onLogout?() }
        }
        .sheet(isPresented: $viewModel.showingChangePassword) {
            changePasswordSheet
        }
        .alert("Password Changed", isPresented: $viewModel.changePasswordSuccess) {
            Button("OK") {}
        } message: {
            Text("Your password has been changed successfully.")
        }
    }

    private var changePasswordSheet: some View {
        NavigationStack {
            Form {
                SecureField("Current Password", text: $viewModel.currentPassword)
                    .textContentType(.password)
                SecureField("New Password", text: $viewModel.newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm New Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingChangePassword = false
                        viewModel.currentPassword = ""
                        viewModel.newPassword = ""
                        viewModel.confirmPassword = ""
                        viewModel.error = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.changePassword() }
                    } label: {
                        if viewModel.isChangingPassword {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(
                        viewModel.isChangingPassword
                        || viewModel.currentPassword.isEmpty
                        || viewModel.newPassword.isEmpty
                        || viewModel.confirmPassword.isEmpty
                    )
                }
            }
            .onChange(of: viewModel.changePasswordSuccess) { _, success in
                if success { viewModel.showingChangePassword = false }
            }
        }
    }

    // MARK: - About Section

    var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: AppConfiguration.appVersion)
            LabeledContent("Build", value: AppConfiguration.buildNumber)

            Link(destination: URL(string: "https://apps.apple.com/app/ultratrain")!) {
                Label("Rate on App Store", systemImage: "star")
            }
            .accessibilityHint("Opens the App Store to rate UltraTrain")

            Link(destination: URL(string: "mailto:support@ultratrain.app?subject=UltraTrain%20Feedback")!) {
                Label("Send Feedback", systemImage: "envelope")
            }
            .accessibilityHint("Opens an email to send feedback to the UltraTrain team")

            Link(destination: URL(string: "https://ultratrain.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            .accessibilityHint("Opens the privacy policy in your browser")

            Link(destination: URL(string: "https://ultratrain.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            .accessibilityHint("Opens the terms of service in your browser")
        }
    }
}
