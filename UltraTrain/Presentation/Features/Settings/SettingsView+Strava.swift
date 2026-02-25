import SwiftUI

// MARK: - Strava Section

extension SettingsView {
    var stravaSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Strava")
                    Text(stravaStatusDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(stravaStatusColor)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)

            switch viewModel.stravaStatus {
            case .disconnected, .error:
                Button {
                    Task { await viewModel.connectStrava() }
                } label: {
                    if viewModel.isConnectingStrava {
                        ProgressView()
                    } else {
                        Text("Connect to Strava")
                            .foregroundStyle(Color.orange)
                    }
                }
                .disabled(viewModel.isConnectingStrava)
                .accessibilityHint("Connects your Strava account to automatically upload runs")

            case .connecting:
                ProgressView("Connecting...")

            case .connected:
                if let settings = viewModel.appSettings {
                    Toggle("Auto-Upload Runs", isOn: Binding(
                        get: { settings.stravaAutoUploadEnabled },
                        set: { newValue in
                            Task { await viewModel.updateStravaAutoUpload(newValue) }
                        }
                    ))
                    .accessibilityHint("Automatically uploads completed runs to Strava")
                }
                if viewModel.stravaQueuePendingCount > 0 {
                    LabeledContent(
                        "Pending Uploads",
                        value: "\(viewModel.stravaQueuePendingCount)"
                    )
                }
                Button(role: .destructive) {
                    Task { await viewModel.disconnectStrava() }
                } label: {
                    Text("Disconnect Strava")
                }
                .accessibilityHint("Removes the connection to your Strava account")
            }
        } header: {
            Text("Connected Services")
        }
    }

    private var stravaStatusDescription: String {
        switch viewModel.stravaStatus {
        case .disconnected: "Not connected"
        case .connecting: "Connecting..."
        case .connected(let name): "Connected as \(name)"
        case .error(let msg): "Error: \(msg)"
        }
    }

    private var stravaStatusColor: Color {
        switch viewModel.stravaStatus {
        case .disconnected, .error: .gray
        case .connecting: .orange
        case .connected: .orange
        }
    }
}
