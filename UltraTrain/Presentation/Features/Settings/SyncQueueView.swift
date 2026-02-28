import SwiftUI

struct SyncQueueView: View {
    @State private var viewModel: SyncQueueViewModel
    @State private var showingDiscardAllConfirmation = false

    init(syncService: any SyncQueueServiceProtocol) {
        _viewModel = State(initialValue: SyncQueueViewModel(syncService: syncService))
    }

    var body: some View {
        List {
            statusSection

            if !viewModel.failedItems.isEmpty {
                failedItemsSection
            }
        }
        .navigationTitle("Sync Queue")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .confirmationDialog(
            "Discard All Failed",
            isPresented: $showingDiscardAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard All", role: .destructive) {
                Task { await viewModel.discardAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all failed sync items. The data remains on your device but won't be synced to the server.")
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section {
            LabeledContent("Pending", value: "\(viewModel.pendingCount)")
            LabeledContent("Failed", value: "\(viewModel.failedItems.count)")
        } header: {
            Text("Status")
        } footer: {
            Text("Pending items sync automatically when a connection is available. Failed items may need manual retry.")
        }
    }

    // MARK: - Failed Items Section

    private var failedItemsSection: some View {
        Section {
            ForEach(viewModel.failedItems) { item in
                failedItemRow(item)
            }

            if viewModel.failedItems.count > 1 {
                Button {
                    Task { await viewModel.retryAll() }
                } label: {
                    HStack {
                        Label("Retry All", systemImage: "arrow.clockwise")
                        if viewModel.isRetrying {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(viewModel.isRetrying)

                Button(role: .destructive) {
                    showingDiscardAllConfirmation = true
                } label: {
                    Label("Discard All", systemImage: "trash")
                }
            }
        } header: {
            Text("Failed Items")
        }
    }

    private func failedItemRow(_ item: SyncQueueItem) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Label(operationLabel(item.operationType), systemImage: operationIcon(item.operationType))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("Attempt \(item.retryCount)/5")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if let error = item.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.danger)
                    .lineLimit(2)
            }

            if let lastAttempt = item.lastAttempt {
                Text("Last tried \(lastAttempt, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            HStack(spacing: Theme.Spacing.md) {
                Button {
                    Task { await viewModel.retryItem(item) }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption)
                }

                Button(role: .destructive) {
                    Task { await viewModel.discardItem(item) }
                } label: {
                    Label("Discard", systemImage: "xmark")
                        .font(.caption)
                }
            }
            .buttonStyle(.borderless)
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Helpers

    private func operationLabel(_ type: SyncOperationType) -> String {
        switch type {
        case .runUpload: "Run Upload"
        case .athleteSync: "Profile Sync"
        case .raceSync: "Race Sync"
        case .raceDelete: "Race Delete"
        case .trainingPlanSync: "Plan Sync"
        case .nutritionPlanSync: "Nutrition Sync"
        case .fitnessSnapshotSync: "Fitness Sync"
        case .finishEstimateSync: "Estimate Sync"
        case .socialProfileSync: "Social Profile Sync"
        case .activityPublish: "Activity Publish"
        case .shareRevoke: "Share Revoke"
        }
    }

    private func operationIcon(_ type: SyncOperationType) -> String {
        switch type {
        case .runUpload: "figure.run"
        case .athleteSync: "person"
        case .raceSync: "flag"
        case .raceDelete: "flag.slash"
        case .trainingPlanSync: "calendar"
        case .nutritionPlanSync: "fork.knife"
        case .fitnessSnapshotSync: "heart.text.square"
        case .finishEstimateSync: "timer"
        case .socialProfileSync: "person.crop.circle"
        case .activityPublish: "megaphone"
        case .shareRevoke: "xmark.circle"
        }
    }
}
