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
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if let athlete = viewModel.athlete {
                    let estimates = MultiDistanceEstimator.estimates(for: athlete)
                    if estimates.allSatisfy({ $0.projectedSeconds == nil }) {
                        emptyStateCard
                    } else {
                        recordsCard(estimates: estimates)
                        footerCaption
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.Colors.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.xl)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle(Text(String(localized: "pr.title", defaultValue: "Personal records")))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    presetDistance = nil
                    showingEditSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.accentColor)
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

    // MARK: - Records card

    private func recordsCard(estimates: [MultiDistanceEstimator.Estimate]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader

            VStack(spacing: 0) {
                ForEach(Array(estimates.enumerated()), id: \.element.distance) { idx, estimate in
                    Button {
                        presetDistance = estimate.distance
                        showingEditSheet = true
                    } label: {
                        row(for: estimate)
                    }
                    .buttonStyle(.plain)

                    if idx < estimates.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.06))
                    }
                }
            }
        }
        .futuristicGlassStyle()
    }

    private var sectionHeader: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "stopwatch")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Colors.accentColor)
            Text(String(localized: "pr.section.title", defaultValue: "Your records").uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.bottom, 2)
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for estimate: MultiDistanceEstimator.Estimate) -> some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(estimate.distance.shortLabel)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.Colors.label)
                statusRow(for: estimate)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString(estimate))
                    .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(estimate.recordedPR != nil
                                     ? Theme.Colors.accentColor
                                     : Theme.Colors.label)
                if let pace = estimate.pacePerKm {
                    Text("\(formatPace(pace))/km")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statusRow(for estimate: MultiDistanceEstimator.Estimate) -> some View {
        HStack(spacing: 6) {
            if let pr = estimate.recordedPR {
                Text("PR")
                    .font(.caption2.weight(.heavy))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Theme.Colors.accentColor.opacity(0.18))
                    )
                Text(pr.date, format: .dateTime.month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else if estimate.projectedSeconds != nil {
                Text(String(localized: "pr.row.projected", defaultValue: "Projected").uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.secondaryLabel.opacity(0.35), lineWidth: 0.5)
                    )
            } else {
                Text(String(localized: "pr.row.unknown", defaultValue: "Add a PR to estimate"))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    private func timeString(_ estimate: MultiDistanceEstimator.Estimate) -> String {
        guard let seconds = estimate.projectedSeconds else { return "--" }
        return formatTime(seconds)
    }

    // MARK: - Footer caption

    private var footerCaption: some View {
        Text(String(localized: "pr.section.footer",
                    defaultValue: "Recorded PRs anchor your training paces. Projections are estimates from your other data. Log a PR at that distance to lock it in."))
            .font(.footnote)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.xs)
    }

    // MARK: - Empty state

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "stopwatch")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.accentColor)
                Text(String(localized: "pr.empty.title", defaultValue: "No fitness data yet"))
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.Colors.label)
            }
            Text(String(localized: "pr.empty.body",
                        defaultValue: "Log a recent race time and we'll project your fitness across every distance, then calibrate your training paces."))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                presetDistance = nil
                showingEditSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(String(localized: "pr.empty.cta", defaultValue: "Log your first PR"))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    Capsule().fill(Theme.Colors.accentColor)
                )
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .futuristicGlassStyle()
    }

    // MARK: - Overlay

    private var recalibrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
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
            .futuristicGlassStyle()
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
