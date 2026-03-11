import SwiftUI

struct PersonalBestsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var expandedDistance: PersonalBestDistance?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                headerSection

                pbCard(
                    distance: .fiveK,
                    hours: $viewModel.pb5kHours,
                    minutes: $viewModel.pb5kMinutes,
                    seconds: $viewModel.pb5kSeconds,
                    date: $viewModel.pb5kDate,
                    maxHours: 2
                )
                pbCard(
                    distance: .tenK,
                    hours: $viewModel.pb10kHours,
                    minutes: $viewModel.pb10kMinutes,
                    seconds: $viewModel.pb10kSeconds,
                    date: $viewModel.pb10kDate,
                    maxHours: 3
                )
                pbCard(
                    distance: .halfMarathon,
                    hours: $viewModel.pbHalfHours,
                    minutes: $viewModel.pbHalfMinutes,
                    seconds: $viewModel.pbHalfSeconds,
                    date: $viewModel.pbHalfDate,
                    maxHours: 6
                )
                pbCard(
                    distance: .marathon,
                    hours: $viewModel.pbMarathonHours,
                    minutes: $viewModel.pbMarathonMinutes,
                    seconds: $viewModel.pbMarathonSeconds,
                    date: $viewModel.pbMarathonDate,
                    maxHours: 12
                )

                suggestionSection
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(Theme.Gradients.warmCoralCTA))
                .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 8, y: 4)

            Text("Your Race Times")
                .font(.title2.bold())
            Text("Enter at least one PB to calibrate your training paces.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.bottom, Theme.Spacing.xs)
    }

    private func pbCard(
        distance: PersonalBestDistance,
        hours: Binding<Int>,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        date: Binding<Date>,
        maxHours: Int
    ) -> some View {
        PBEntryCard(
            distance: distance,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            date: date,
            maxHours: maxHours,
            isExpanded: expandedDistance == distance,
            estimatedTime: estimatedTime(for: distance),
            onToggle: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedDistance = expandedDistance == distance ? nil : distance
                }
            }
        )
    }

    private func estimatedTime(for distance: PersonalBestDistance) -> String? {
        let knownPBs = viewModel.buildCurrentPBs()
        guard !knownPBs.isEmpty else { return nil }
        // Don't show estimate if user already entered this distance
        if knownPBs.contains(where: { $0.distance == distance }) { return nil }
        let allPBs = PerformanceEstimator.deduceMissingPBs(from: knownPBs)
        guard let estimated = allPBs.first(where: { $0.distance == distance }) else { return nil }
        return "~\(formatSeconds(estimated.timeSeconds))"
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    @ViewBuilder
    private var suggestionSection: some View {
        if viewModel.buildCurrentPBs().isEmpty {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Never raced? A 5K time trial will help calibrate your training paces.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.md)
            .onboardingCardStyle()
        }
    }
}

// MARK: - PB Entry Card

private struct PBEntryCard: View {
    let distance: PersonalBestDistance
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var date: Date
    let maxHours: Int
    let isExpanded: Bool
    let estimatedTime: String?
    let onToggle: () -> Void

    private var hasTime: Bool {
        totalSeconds > 0
    }

    private var totalSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }

    /// Minimum allowed time per distance (world record - 60 seconds).
    private var minAllowedSeconds: Int {
        switch distance {
        case .fiveK: return 695          // WR 12:35 - 60s
        case .tenK: return 1511          // WR 26:11 - 60s
        case .halfMarathon: return 3391  // WR 57:31 - 60s
        case .marathon: return 7175      // WR 2:00:35 - 60s
        }
    }

    private var isTooFast: Bool {
        hasTime && totalSeconds < minAllowedSeconds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack {
                    Text(distance.rawValue)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    Spacer()
                    if hasTime {
                        Text(formattedTime)
                            .font(.subheadline.monospacedDigit().bold())
                            .foregroundStyle(isTooFast ? Theme.Colors.danger : Theme.Colors.warmCoral)
                    } else if let estimate = estimatedTime {
                        Text(estimate)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.6))
                    } else {
                        Text("Tap to add")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.tertiaryLabel)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Expanded time input
            if isExpanded {
                Divider()
                    .padding(.vertical, Theme.Spacing.sm)

                compactTimeInput
                    .padding(.bottom, Theme.Spacing.xs)

                if isTooFast {
                    Label("Time is faster than the world record", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                        .padding(.bottom, Theme.Spacing.xs)
                }

                DatePicker(
                    "Date",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(.subheadline)
            }
        }
        .onboardingCardStyle()
        .accessibilityIdentifier("onboarding.pb.\(distance.rawValue)")
    }

    // Compact time input: 3 columns with +/- buttons and tap-to-type
    private var compactTimeInput: some View {
        HStack(spacing: 0) {
            CompactTimeColumn(label: "H", value: $hours, range: 0...maxHours)
            CompactTimeColumn(label: "M", value: $minutes, range: 0...59)
            CompactTimeColumn(label: "S", value: $seconds, range: 0...59)
        }
    }

    private var formattedTime: String {
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Compact Time Column (tap-to-type + stepper)

private struct CompactTimeColumn: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.Colors.secondaryLabel)

            HStack(spacing: 6) {
                Button {
                    value = max(range.lowerBound, value - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.body)
                        .foregroundStyle(Theme.Colors.warmCoral.opacity(0.8))
                }
                .buttonStyle(.plain)

                if isEditing {
                    TextField("", text: $editText)
                        .keyboardType(.numberPad)
                        .font(.title3.monospacedDigit().bold())
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 32)
                        .focused($isFocused)
                        .onSubmit { commitEdit() }
                        .onChange(of: isFocused) { _, focused in
                            if !focused { commitEdit() }
                        }
                } else {
                    Text("\(value)")
                        .font(.title3.monospacedDigit().bold())
                        .frame(minWidth: 28)
                        .multilineTextAlignment(.center)
                        .contentShape(Rectangle())
                        .onTapGesture { beginEdit() }
                }

                Button {
                    value = min(range.upperBound, value + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(Theme.Colors.warmCoral.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func beginEdit() {
        editText = "\(value)"
        isEditing = true
        isFocused = true
    }

    private func commitEdit() {
        if let parsed = Int(editText) {
            value = min(range.upperBound, max(range.lowerBound, parsed))
        }
        isEditing = false
    }
}
