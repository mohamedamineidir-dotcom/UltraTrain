import SwiftUI

/// Personal records page: lists the athlete's PRs across the four
/// standard road distances (5K / 10K / Half / Marathon) plus
/// fitness-projected times for distances they haven't yet raced.
/// Logging a new PR that exceeds the current fitness estimate
/// triggers an automatic recalibration of remaining sessions in the
/// active plan.
struct PersonalRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State var viewModel: ProfileViewModel
    @State private var showingEditSheet = false
    @State private var presetDistance: PersonalBestDistance? = nil
    @State private var recalibrationSummary: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if let athlete = viewModel.athlete {
                    let officialPRs = sortedOfficialPRs(athlete)
                    let fitness = MultiDistanceEstimator.fitnessProjections(
                        for: athlete, recentRuns: viewModel.recentRuns
                    )
                    if officialPRs.isEmpty && fitness == nil {
                        emptyStateCard
                    } else {
                        if !officialPRs.isEmpty {
                            officialPRsCard(officialPRs)
                        }
                        if let fitness {
                            fitnessEstimateCard(fitness)
                                .premiumLocked(
                                    title: String(localized: "premium.lock.fitness.title",
                                                  defaultValue: "Current fitness"),
                                    message: String(localized: "premium.lock.fitness.message",
                                                    defaultValue: "Unlock your live fitness estimate across every distance.")
                                )
                        }
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
        .background(
            Theme.Gradients.futuristicBackground(colorScheme: colorScheme)
                .ignoresSafeArea()
        )
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

    // MARK: - Block 1: Official PRs

    /// The athlete's actually-entered PRs, ordered by distance. These are
    /// historical facts, they can be mutually inconsistent (a stellar 10K
    /// next to an old 5K) and that's fine, they're what the athlete ran.
    private func sortedOfficialPRs(_ athlete: Athlete) -> [PersonalBest] {
        let order = PersonalBestDistance.allCases
        return athlete.personalBests
            .filter { $0.timeSeconds > 0 }
            .sorted {
                (order.firstIndex(of: $0.distance) ?? 0) < (order.firstIndex(of: $1.distance) ?? 0)
            }
    }

    private func officialPRsCard(_ prs: [PersonalBest]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            blockHeader(
                title: String(localized: "pr.block.official", defaultValue: "Your records"),
                icon: "stopwatch",
                subtitle: nil
            )
            VStack(spacing: 0) {
                ForEach(Array(prs.enumerated()), id: \.element.id) { idx, pr in
                    Button {
                        presetDistance = pr.distance
                        showingEditSheet = true
                    } label: {
                        prRow(
                            distance: pr.distance,
                            seconds: pr.timeSeconds,
                            pacePerKm: pr.pacePerKm,
                            date: pr.date,
                            isOfficial: true
                        )
                    }
                    .buttonStyle(.plain)
                    if idx < prs.count - 1 { rowDivider }
                }
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - Block 2: Current fitness estimate

    /// A single consistent set of equivalents projected from the athlete's
    /// best recent result, so the four distances are always monotonic.
    /// This is the "current fitness" read, it shifts as the anchor PR /
    /// VMA changes and jumps when a new PR beats the estimate.
    private func fitnessEstimateCard(_ estimates: [MultiDistanceEstimator.Estimate]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            blockHeader(
                title: String(localized: "pr.block.fitness", defaultValue: "Current fitness"),
                icon: "chart.line.uptrend.xyaxis",
                subtitle: String(localized: "pr.block.fitness.subtitle",
                                 defaultValue: "Equivalent times from your best recent result")
            )
            VStack(spacing: 0) {
                ForEach(Array(estimates.enumerated()), id: \.element.distance) { idx, est in
                    Button {
                        presetDistance = est.distance
                        showingEditSheet = true
                    } label: {
                        prRow(
                            distance: est.distance,
                            seconds: est.projectedSeconds ?? 0,
                            pacePerKm: est.pacePerKm ?? 0,
                            date: nil,
                            isOfficial: false
                        )
                    }
                    .buttonStyle(.plain)
                    if idx < estimates.count - 1 { rowDivider }
                }
            }
        }
        .futuristicGlassStyle()
    }

    // MARK: - Shared row + header

    private func blockHeader(title: String, icon: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accentColor)
                Text(title.uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(0.8)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
        }
        .padding(.bottom, 2)
    }

    private var rowDivider: some View {
        Divider().background(Color.white.opacity(0.06))
    }

    /// Shared row for both blocks. `isOfficial` rows (real PRs) glow in
    /// the distance accent and carry a PR badge + date; estimate rows sit
    /// muted with an "Estimated" tag so the eye separates earned times
    /// from projected ones.
    @ViewBuilder
    private func prRow(
        distance: PersonalBestDistance,
        seconds: TimeInterval,
        pacePerKm: TimeInterval,
        date: Date?,
        isOfficial: Bool
    ) -> some View {
        let accent = distance.accent
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(accent.opacity(isOfficial ? 0.16 : 0.07))
                Circle()
                    .stroke(accent.opacity(isOfficial ? 0.4 : 0.18), lineWidth: 1)
                Image(systemName: distance.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isOfficial ? accent : Theme.Colors.secondaryLabel)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(distance.shortLabel)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.Colors.label)
                if let date {
                    HStack(spacing: 6) {
                        Text("PR")
                            .font(.caption2.weight(.heavy))
                            .tracking(0.5)
                            .foregroundStyle(accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accent.opacity(0.18)))
                        Text(date, format: .dateTime.month(.abbreviated).year())
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                } else {
                    Text(String(localized: "pr.row.estimated", defaultValue: "Estimated").uppercased())
                        .font(.caption2.weight(.heavy))
                        .tracking(0.5)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            Capsule()
                                .stroke(Theme.Colors.secondaryLabel.opacity(0.35), lineWidth: 0.5)
                        )
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(seconds))
                    .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(isOfficial ? accent : Theme.Colors.label)
                Text("\(formatPace(pacePerKm))/km")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Footer caption

    private var footerCaption: some View {
        Text(String(localized: "pr.section.footer",
                    defaultValue: "Your records are the times you've actually run. Current fitness projects equivalents across every distance from your best recent result, and updates as you train or log a faster PR."))
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
