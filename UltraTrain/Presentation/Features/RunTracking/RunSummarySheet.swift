import SwiftUI

struct RunSummarySheet: View {
    @Bindable var viewModel: ActiveRunViewModel
    let onDismiss: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var headerIconSize: CGFloat = 48
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    statsSection
                    if !viewModel.routeCoordinates.isEmpty {
                        RunMapView(
                            coordinates: viewModel.routeCoordinates,
                            showsUserLocation: false,
                            startCoordinate: viewModel.routeCoordinates.first,
                            endCoordinate: viewModel.routeCoordinates.last,
                            height: 180
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    notesSection
                    linkedSessionBanner
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .navigationTitle("Run Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        viewModel.discardRun()
                        onDismiss()
                    }
                    .foregroundStyle(Theme.Colors.danger)
                    .accessibilityIdentifier("runTracking.discardButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveRun(notes: notes.isEmpty ? nil : notes)
                            onDismiss()
                        }
                    }
                    .bold()
                    .disabled(viewModel.isSaving)
                    .accessibilityIdentifier("runTracking.saveButton")
                }
            }
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: headerIconSize))
                .foregroundStyle(Theme.Colors.success)
                .accessibilityHidden(true)
            Text("Great Run!")
                .font(.title2.bold())
            Text(viewModel.formattedTime)
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            summaryTile(label: "Distance", value: "\(viewModel.formattedDistance) km")
            if viewModel.pausedDuration > 0 {
                summaryTile(label: "Moving Time", value: viewModel.formattedTime)
                summaryTile(label: "Total Time", value: viewModel.formattedTotalTime)
            }
            summaryTile(label: "Avg Pace", value: "\(viewModel.formattedPace) /km")
            summaryTile(label: "Elevation", value: viewModel.formattedElevation)
            summaryTile(
                label: "Heart Rate",
                value: viewModel.currentHeartRate.map { "\($0) bpm" } ?? "N/A"
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes")
                .font(.headline)
            TextField("How did it feel?", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    @ViewBuilder
    private var linkedSessionBanner: some View {
        if let session = viewModel.linkedSession {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(Theme.Colors.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Linked Session")
                        .font(.caption.bold())
                    Text("\(session.type.rawValue.capitalized) — \(String(format: "%.1f km", session.plannedDistanceKm))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary.opacity(0.08))
            )
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Helper

    private func summaryTile(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }
}
