import SwiftUI

/// Personal records page: lists the athlete's PRs across the four
/// standard road distances (5K / 10K / Half / Marathon) plus
/// fitness-projected times for distances they haven't yet raced.
/// Logging a new PR that exceeds the current fitness estimate
/// triggers an automatic recalibration of remaining sessions in the
/// active plan.
struct PersonalRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ProfileViewModel
    @State private var showingEditSheet = false
    @State private var presetDistance: PersonalBestDistance? = nil
    @State private var recalibrationSummary: String? = nil

    var body: some View {
        List {
            if let athlete = viewModel.athlete {
                Section {
                    let estimates = MultiDistanceEstimator.estimates(for: athlete)
                    if estimates.allSatisfy({ $0.projectedSeconds == nil }) {
                        emptyStateRow
                    } else {
                        ForEach(estimates, id: \.distance) { estimate in
                            Button {
                                presetDistance = estimate.distance
                                showingEditSheet = true
                            } label: {
                                row(for: estimate)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text(String(localized: "pr.section.title", defaultValue: "Your records"))
                } footer: {
                    Text(String(localized: "pr.section.footer",
                                defaultValue: "Recorded PRs anchor your training paces. Projections are estimates from your other data — log a PR at that distance to lock it in."))
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle(Text(String(localized: "pr.title", defaultValue: "Personal records")))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presetDistance = nil
                    showingEditSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityLabel(String(localized: "pr.add.accessibility",
                                                   defaultValue: "Log a new PR"))
                }
                .accessibilityIdentifier("pr.addButton")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPersonalBestSheet(
                presetDistance: presetDistance,
                athlete: viewModel.athlete
            ) { newPR in
                Task {
                    let count = await viewModel.logPersonalBest(newPR)
                    if count > 0 {
                        recalibrationSummary = String(
                            format: String(localized: "pr.recalibration.summary",
                                           defaultValue: "%d session(s) updated to match your new fitness."),
                            count
                        )
                    }
                }
            }
        }
        .overlay {
            if viewModel.isRecalibrating {
                recalibrationOverlay
            }
        }
        .alert(
            Text(String(localized: "pr.recalibration.alertTitle", defaultValue: "Plan updated")),
            isPresented: Binding(
                get: { recalibrationSummary != nil },
                set: { if !$0 { recalibrationSummary = nil } }
            ),
            presenting: recalibrationSummary
        ) { _ in
            Button(String(localized: "common.ok", defaultValue: "OK")) {}
        } message: { summary in
            Text(summary)
        }
        .task {
            if viewModel.athlete == nil { await viewModel.load() }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for estimate: MultiDistanceEstimator.Estimate) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(estimate.distance.shortLabel)
                    .font(.body.bold())
                    .foregroundStyle(Theme.Colors.label)
                subtitle(for: estimate)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString(estimate))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
                if let pace = estimate.pacePerKm {
                    Text("\(formatPace(pace))/km")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func subtitle(for estimate: MultiDistanceEstimator.Estimate) -> Text {
        if let pr = estimate.recordedPR {
            return Text(pr.date, format: .dateTime.month(.abbreviated).year())
        }
        if estimate.projectedSeconds != nil {
            return Text(String(localized: "pr.row.projected", defaultValue: "Projected"))
        }
        return Text(String(localized: "pr.row.unknown", defaultValue: "Add a PR to estimate"))
    }

    private func timeString(_ estimate: MultiDistanceEstimator.Estimate) -> String {
        guard let seconds = estimate.projectedSeconds else { return "—" }
        return formatTime(seconds)
    }

    // MARK: - Empty state

    private var emptyStateRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(String(localized: "pr.empty.title", defaultValue: "No fitness data yet"))
                .font(.headline)
            Text(String(localized: "pr.empty.body",
                        defaultValue: "Log a recent race time and we'll project your fitness across every distance, then calibrate your training paces."))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Button {
                presetDistance = nil
                showingEditSheet = true
            } label: {
                Label(
                    String(localized: "pr.empty.cta", defaultValue: "Log your first PR"),
                    systemImage: "plus.circle.fill"
                )
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Overlay

    private var recalibrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(String(localized: "pr.recalibration.message",
                            defaultValue: "Updating your training paces…"))
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(Theme.Spacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func formatPace(_ secondsPerKm: TimeInterval) -> String {
        let total = Int(secondsPerKm.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
