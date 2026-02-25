import SwiftUI

// MARK: - iCloud, Privacy, Sync Queue, Data Retention & Data Management Sections

extension SettingsView {
    // MARK: - iCloud Section

    var iCloudSection: some View {
        Section {
            Toggle("iCloud Sync", isOn: Binding(
                get: { viewModel.iCloudSyncEnabled },
                set: { newValue in viewModel.toggleiCloudSync(newValue) }
            ))
            .accessibilityHint("Syncs your training data across all your Apple devices via iCloud")

            if viewModel.iCloudSyncEnabled {
                Label {
                    Text("Data syncs automatically across your devices.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                } icon: {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
            } else {
                Label {
                    Text("Enable to sync training data across iPhone and iPad.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                } icon: {
                    Image(systemName: "icloud.slash")
                        .foregroundStyle(.gray)
                        .accessibilityHidden(true)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Changing this setting requires an app restart to take effect.")
        }
        .alert("Restart Required", isPresented: $viewModel.showRestartAlert) {
            Button("OK") {}
        } message: {
            Text("Please close and reopen UltraTrain for the iCloud sync change to take effect.")
        }
    }

    // MARK: - Privacy Section

    var privacySection: some View {
        Section {
            HStack {
                Label("Tracking Permission", systemImage: "hand.raised")
                Spacer()
                Text(viewModel.trackingStatus.displayDescription)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if viewModel.trackingStatus == .notDetermined {
                Button("Request Permission") {
                    Task { await viewModel.requestTrackingPermission() }
                }
                .accessibilityHint("Requests App Tracking Transparency permission")
            } else if viewModel.trackingStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .accessibilityHint("Opens iOS Settings to change tracking permission")
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("UltraTrain only collects anonymous usage data. No personal information is shared with third parties.")
        }
    }

    // MARK: - Sync Queue Section

    @ViewBuilder
    var syncQueueSection: some View {
        if let syncService {
            Section {
                NavigationLink {
                    SyncQueueView(syncService: syncService)
                } label: {
                    HStack {
                        Label("Sync Queue", systemImage: "arrow.triangle.2.circlepath.circle")
                        Spacer()
                        if let monitor = syncStatusMonitor {
                            if monitor.hasFailures {
                                Text("\(monitor.failedCount) failed")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.danger)
                            } else if monitor.hasPending {
                                Text("\(monitor.pendingCount) pending")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            } else {
                                Text("All synced")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            }
                        }
                    }
                }
                .accessibilityHint("View and manage pending and failed sync items")
            } header: {
                Text("Server Sync")
            }
        }
    }

    // MARK: - Data Retention Section

    @ViewBuilder
    var dataRetentionSection: some View {
        if let settings = viewModel.appSettings {
            Section {
                Picker("Keep Data For", selection: Binding(
                    get: { settings.dataRetentionMonths },
                    set: { months in
                        Task { await viewModel.updateDataRetention(months) }
                    }
                )) {
                    Text("Forever").tag(0)
                    Text("6 Months").tag(6)
                    Text("12 Months").tag(12)
                    Text("24 Months").tag(24)
                }
                .accessibilityHint("Choose how long to keep training data")
            } header: {
                Text("Data Retention")
            } footer: {
                Text("Older data will be automatically removed. Set to Forever to keep all data.")
            }
        }
    }

    // MARK: - Data Management Section

    var dataManagementSection: some View {
        Section("Data") {
            Button {
                Task { await viewModel.exportAllRunsAsCSV() }
            } label: {
                HStack {
                    Label("Export Training Data", systemImage: "square.and.arrow.up")
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isExporting)
            .accessibilityIdentifier("settings.exportButton")
            .accessibilityHint("Exports all your training data as a CSV file for sharing")
            .onChange(of: viewModel.exportedFileURL) {
                if viewModel.exportedFileURL != nil {
                    showingShareSheet = true
                }
            }

            Button(role: .destructive) {
                viewModel.showingClearDataConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
            .accessibilityIdentifier("settings.clearDataButton")
            .accessibilityHint("Permanently deletes all training data, plans, and settings")
        }
    }
}
