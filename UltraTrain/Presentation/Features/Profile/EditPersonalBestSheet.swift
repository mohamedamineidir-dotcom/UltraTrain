import SwiftUI

/// Sheet for adding or updating a personal record at one of the four
/// standard road distances. Pre-populates from any existing PR at the
/// selected distance, the athlete can replace or edit it.
struct EditPersonalBestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let presetDistance: PersonalBestDistance?
    let athlete: Athlete?
    let onSave: (PersonalBest) -> Void

    @State private var distance: PersonalBestDistance
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var date: Date

    init(
        presetDistance: PersonalBestDistance?,
        athlete: Athlete?,
        onSave: @escaping (PersonalBest) -> Void
    ) {
        self.presetDistance = presetDistance
        self.athlete = athlete
        self.onSave = onSave

        let initialDistance = presetDistance ?? .tenK
        _distance = State(initialValue: initialDistance)

        let existing = athlete?.personalBests.first { $0.distance == initialDistance }
        let totalSeconds = Int((existing?.timeSeconds ?? 0).rounded())
        _hours = State(initialValue: totalSeconds / 3600)
        _minutes = State(initialValue: (totalSeconds % 3600) / 60)
        _seconds = State(initialValue: totalSeconds % 60)
        _date = State(initialValue: existing?.date ?? .now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Gradients.futuristicBackground(colorScheme: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        distanceSection
                        timeSection
                        dateSection
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
            .navigationTitle(Text(
                String(localized: "pr.edit.title", defaultValue: "Log a PR")
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save", defaultValue: "Save")) {
                        save()
                    }
                    .font(.headline)
                    .foregroundStyle(isValid ? distance.accent : Theme.Colors.tertiaryLabel)
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Distance

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel(String(localized: "pr.edit.distance", defaultValue: "Distance"),
                         icon: "ruler")
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(PersonalBestDistance.allCases, id: \.self) { d in
                    distanceChip(d)
                }
            }
        }
    }

    private func distanceChip(_ d: PersonalBestDistance) -> some View {
        let isSelected = d == distance
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectDistance(d)
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: d.icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(d.shortLabel)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? d.accent : Theme.Colors.secondaryLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected
                          ? AnyShapeStyle(d.accent.opacity(0.16))
                          : AnyShapeStyle(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.5 : 1)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? d.accent.opacity(0.6) : Color.white.opacity(0.10),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(d.shortLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Time

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel(String(localized: "pr.edit.time", defaultValue: "Time"),
                         icon: "stopwatch")

            VStack(spacing: Theme.Spacing.md) {
                // Live hero readout: the assembled finish time plus the
                // derived per-km pace, updating as the wheels turn. Gives
                // immediate, professional data feedback and lets the
                // athlete sanity-check the entry at a glance.
                VStack(spacing: 4) {
                    Text(totalSeconds > 0 ? formatTime(TimeInterval(totalSeconds)) : "--:--")
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(totalSeconds > 0 ? distance.accent : Theme.Colors.tertiaryLabel)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: totalSeconds)
                    referenceLine
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: Theme.Spacing.sm) {
                    timeColumn(
                        label: String(localized: "common.hours", defaultValue: "h"),
                        value: $hours,
                        range: 0...9
                    )
                    timeColumn(
                        label: String(localized: "common.minutes", defaultValue: "m"),
                        value: $minutes,
                        range: 0...59
                    )
                    timeColumn(
                        label: String(localized: "common.seconds", defaultValue: "s"),
                        value: $seconds,
                        range: 0...59
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .futuristicGlassStyle(phaseTint: distance.accent)
        }
    }

    /// Below the hero time: per-km pace once a time is entered, plus a
    /// contextual badge comparing the entry to any existing PR at this
    /// distance ("New PR" when it beats it, otherwise the current best).
    @ViewBuilder
    private var referenceLine: some View {
        if totalSeconds <= 0 {
            Text(String(localized: "pr.edit.timePrompt",
                        defaultValue: "Set your finish time"))
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        } else {
            HStack(spacing: Theme.Spacing.sm) {
                if let pace = pacePerKm {
                    Text("\(formatPace(pace))/km")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                if let existing = existingPR, existing.timeSeconds > 0 {
                    if TimeInterval(totalSeconds) < existing.timeSeconds {
                        Label(String(localized: "pr.edit.newBest", defaultValue: "New PR"),
                              systemImage: "checkmark.seal.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.Colors.success)
                    } else {
                        Text(String(format: String(localized: "pr.edit.currentBest",
                                                   defaultValue: "Best %@"),
                                    formatTime(existing.timeSeconds)))
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundStyle(Theme.Colors.tertiaryLabel)
                    }
                }
            }
        }
    }

    private func timeColumn(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(spacing: 4) {
            Picker(label, selection: value) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .clipped()
            Text(label)
                .font(.caption2.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.0))
        )
    }

    // MARK: - Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel(String(localized: "pr.edit.date", defaultValue: "Date"),
                         icon: "calendar")
            HStack {
                Text(String(localized: "pr.edit.dateAchieved", defaultValue: "Achieved on"))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                DatePicker(
                    "",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(distance.accent)
            }
            .futuristicGlassStyle(phaseTint: distance.accent)
        }
    }

    // MARK: - Section label

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(distance.accent)
            Text(text.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.leading, Theme.Spacing.xs)
        .animation(.easeInOut(duration: 0.18), value: distance)
    }

    // MARK: - Derived

    private var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }

    private var isValid: Bool { totalSeconds > 0 }

    private var pacePerKm: TimeInterval? {
        guard totalSeconds > 0, distance.distanceKm > 0 else { return nil }
        return Double(totalSeconds) / distance.distanceKm
    }

    private var existingPR: PersonalBest? {
        athlete?.personalBests.first { $0.distance == distance }
    }

    // MARK: - Actions

    private func selectDistance(_ new: PersonalBestDistance) {
        distance = new
        // Re-prefill from any existing PR at the new distance.
        let existing = athlete?.personalBests.first { $0.distance == new }
        let total = Int((existing?.timeSeconds ?? 0).rounded())
        hours = total / 3600
        minutes = (total % 3600) / 60
        seconds = total % 60
        if let existing { date = existing.date }
    }

    private func save() {
        guard isValid else { return }
        let pr = PersonalBest(
            id: UUID(),
            distance: distance,
            timeSeconds: TimeInterval(totalSeconds),
            date: date
        )
        onSave(pr)
        dismiss()
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
