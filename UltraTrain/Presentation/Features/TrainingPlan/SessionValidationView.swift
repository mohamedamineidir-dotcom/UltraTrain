import SwiftUI

/// Context about where this session sits in the athlete's current week.
/// Surfaced as a progress footer on the validation page so the athlete
/// sees their weekly trajectory — small "I'm making progress" hit after
/// completing a session.
struct WeekProgress: Equatable, Sendable {
    /// 0-based index of this session among the week's running sessions
    /// (rest + S&C excluded).
    let currentSessionIndex: Int
    /// Total running sessions prescribed this week (rest + S&C excluded).
    let totalSessions: Int
    /// Number of running sessions the athlete already completed BEFORE
    /// this one. The validation flow hasn't marked the current session
    /// complete yet when this is built.
    let completedBefore: Int
    /// Display label for the phase context, e.g. "Peak · Week 7".
    let phaseLabel: String
}

struct SessionValidationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    @Environment(\.colorScheme) private var colorScheme

    let session: TrainingSession
    let recentRuns: [CompletedRun]
    let onComplete: (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void
    let onLinkRun: (UUID) -> Void
    var recentRunsProvider: ((Date) async -> [CompletedRun])?
    var stravaActivitiesProvider: ((Date) async -> [StravaActivity])?
    var onLinkStravaActivity: ((StravaActivity) -> Void)?
    /// Supplies the IR-1 per-rep feedback context. When this resolves to a
    /// non-nil value for an intervals/tempo session, the manual stats page
    /// chains into the feedback page *before* the completion animation.
    var intervalFeedbackContextProvider: (() async -> IntervalFeedbackContext?)?
    var onSaveIntervalFeedback: ((IntervalPerformanceFeedback) -> Void)?
    /// Optional week context shown as a progress footer on the manual
    /// stats page. When nil, the footer is hidden.
    var weekProgress: WeekProgress?

    @State private var showCompletion = false
    @State private var path: [ValidationStep] = []
    @State private var fetchedFeedbackContext: IntervalFeedbackContext?

    enum ValidationStep: Hashable {
        case manual
        case syncApp
        case intervalFeedback
    }

    init(
        session: TrainingSession,
        recentRuns: [CompletedRun] = [],
        onComplete: @escaping (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void,
        onLinkRun: @escaping (UUID) -> Void,
        recentRunsProvider: ((Date) async -> [CompletedRun])? = nil,
        stravaActivitiesProvider: ((Date) async -> [StravaActivity])? = nil,
        onLinkStravaActivity: ((StravaActivity) -> Void)? = nil,
        intervalFeedbackContextProvider: (() async -> IntervalFeedbackContext?)? = nil,
        onSaveIntervalFeedback: ((IntervalPerformanceFeedback) -> Void)? = nil,
        weekProgress: WeekProgress? = nil
    ) {
        self.session = session
        self.recentRuns = recentRuns
        self.onComplete = onComplete
        self.onLinkRun = onLinkRun
        self.recentRunsProvider = recentRunsProvider
        self.stravaActivitiesProvider = stravaActivitiesProvider
        self.onLinkStravaActivity = onLinkStravaActivity
        self.intervalFeedbackContextProvider = intervalFeedbackContextProvider
        self.onSaveIntervalFeedback = onSaveIntervalFeedback
        self.weekProgress = weekProgress
    }

    /// True when this session's type warrants a per-rep feedback page after
    /// the basic stats entry. Derived from session.type alone so it is
    /// synchronous and stable at render time (the async context fetch may
    /// not have resolved when ManualValidationPage first appears).
    private var isIntervalOrTempo: Bool {
        session.type == .intervals || session.type == .tempo
    }

    /// True when the chain can actually push the feedback page — needs a
    /// resolved context (fitness-derived target pace). When false for an
    /// intervals/tempo session, the basic page still skips feeling+RPE
    /// (user asked us not to show those on intervals/tempo), but we go
    /// straight to the loading screen on Continue. RPE is then lost for
    /// that session; this only happens when the athlete has no PRs / VMA /
    /// goal time, which is rare in practice.
    private var shouldChainFeedback: Bool {
        isIntervalOrTempo && fetchedFeedbackContext != nil
    }

    var body: some View {
        if showCompletion {
            SessionCompletionLoadingView {
                dismiss()
            }
        } else {
            NavigationStack(path: $path) {
                choicePage
                    .navigationTitle("Validate Session")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { dismiss() }
                        }
                    }
                    .navigationDestination(for: ValidationStep.self) { step in
                        destinationView(for: step)
                    }
            }
            .task {
                if let provider = intervalFeedbackContextProvider, fetchedFeedbackContext == nil {
                    fetchedFeedbackContext = await provider()
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for step: ValidationStep) -> some View {
        switch step {
        case .manual:
            ManualValidationPage(
                session: session,
                hideFeelingAndRPE: isIntervalOrTempo,
                weekProgress: weekProgress,
                onComplete: { dist, dur, elev, feeling, rpe in
                    onComplete(dist, dur, elev, feeling, rpe)
                    if shouldChainFeedback {
                        path.append(.intervalFeedback)
                    } else {
                        withAnimation { showCompletion = true }
                    }
                }
            )
        case .syncApp:
            SyncAppPickerPage(
                session: session,
                recentRuns: recentRuns,
                recentRunsProvider: recentRunsProvider,
                stravaActivitiesProvider: stravaActivitiesProvider,
                onLinkRun: { runId in
                    onLinkRun(runId)
                    dismiss()
                },
                onLinkStravaActivity: { activity in
                    onLinkStravaActivity?(activity)
                    dismiss()
                }
            )
        case .intervalFeedback:
            if let ctx = fetchedFeedbackContext {
                IntervalPerformanceContent(
                    sessionId: ctx.sessionId,
                    sessionLabel: ctx.sessionLabel,
                    sessionType: ctx.sessionType,
                    targetPacePerKm: ctx.targetPacePerKm,
                    prescribedRepCount: ctx.prescribedRepCount,
                    existingFeedback: ctx.existingFeedback,
                    onSave: { feedback in
                        onSaveIntervalFeedback?(feedback)
                        withAnimation { showCompletion = true }
                    },
                    onSkip: {
                        withAnimation { showCompletion = true }
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Choice Page

    private var choicePage: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Session header
            sessionHeader

            // Validation options
            VStack(spacing: Theme.Spacing.md) {
                Text("How do you want to validate?")
                    .font(.headline)

                // Manual entry
                Button {
                    path.append(.manual)
                } label: {
                    validationOptionCard(
                        icon: "pencil.and.list.clipboard",
                        iconColor: Theme.Colors.primary,
                        title: "Enter manually",
                        subtitle: "Type your distance, duration, and elevation."
                    )
                }
                .buttonStyle(.plain)

                // Sync with app
                Button {
                    path.append(.syncApp)
                } label: {
                    validationOptionCard(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: Theme.Colors.warmCoral,
                        title: "Sync from an app",
                        subtitle: "Import from Strava, Garmin, Coros, or Suunto."
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Skip stats shortcut
            Button {
                onComplete(nil, nil, nil, nil, nil)
                withAnimation { showCompletion = true }
            } label: {
                Text("Just mark as completed")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var sessionHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: session.type.icon)
                .font(.title2)
                .foregroundStyle(session.intensity.color)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(session.intensity.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.title3.bold())
                Text(session.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func validationOptionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle()
    }
}

// MARK: - Manual Validation Page

private struct ManualValidationPage: View {
    @Environment(\.unitPreference) private var units
    @Environment(\.colorScheme) private var colorScheme
    let session: TrainingSession
    /// When true, the in-page Feeling + RPE sections are suppressed because
    /// a follow-up per-rep feedback page will capture those signals (IR-1).
    /// Only applied for intervals/tempo sessions that have a feedback
    /// context — easy / long run / recovery sessions still ask here.
    let hideFeelingAndRPE: Bool
    let weekProgress: WeekProgress?
    let onComplete: (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void

    @State private var distanceText: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var elevationText: String
    @State private var feeling: PerceivedFeeling?
    @State private var rpe: Int?
    @State private var pulseOn: Bool = false
    @FocusState private var focusedField: StatsField?

    enum StatsField: Hashable { case distance, elevation }

    init(
        session: TrainingSession,
        hideFeelingAndRPE: Bool = false,
        weekProgress: WeekProgress? = nil,
        onComplete: @escaping (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void
    ) {
        self.session = session
        self.hideFeelingAndRPE = hideFeelingAndRPE
        self.weekProgress = weekProgress
        self.onComplete = onComplete
        // Pre-fill with planned values. First-look is a completed page —
        // the athlete can tap Continue immediately if they ran to plan
        // (the common case). Editing surfaces a diff pill below the row;
        // on-plan stays silent. The previous empty-first design added a
        // "Use X" CTA chip per row which made the first impression busy.
        let planned = session.plannedDuration
        _distanceText = State(initialValue: session.plannedDistanceKm > 0
            ? String(format: "%.1f", session.plannedDistanceKm) : "")
        _hours = State(initialValue: Int(planned) / 3600)
        _minutes = State(initialValue: (Int(planned) % 3600) / 60)
        _seconds = State(initialValue: 0)
        _elevationText = State(initialValue: session.plannedElevationGainM > 0
            ? String(format: "%.0f", session.plannedElevationGainM) : "")
    }

    private var isStrengthSession: Bool {
        session.type == .strengthConditioning
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Single unified card: session context on top, stats rows
                // below. One visual anchor instead of two stacked cards
                // competing for the first look.
                unifiedSessionCard

                if !hideFeelingAndRPE {
                    feelingSection
                    rpeSection
                }

                completeButton

                rationaleCard

                if let progress = weekProgress {
                    weekProgressFooter(progress)
                }

                Button {
                    onComplete(nil, nil, nil, nil, nil)
                } label: {
                    Text("Skip stats, just complete")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
                .padding(.bottom, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Enter Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseOn = true
            }
        }
    }

    /// Single card holding: session context header, then the 3 input
    /// rows separated by a subtle hairline. Pre-filled with planned
    /// values — the athlete's first look is a completed page they can
    /// either accept or tap to refine. Only diff pills appear below
    /// rows whose values have been edited away from plan.
    private var unifiedSessionCard: some View {
        VStack(spacing: 0) {
            // Session header
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                session.intensity.color.opacity(colorScheme == .dark ? 0.45 : 0.22),
                                session.intensity.color.opacity(colorScheme == .dark ? 0.18 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().stroke(session.intensity.color.opacity(0.35), lineWidth: 0.75)
                        )
                    Image(systemName: session.type.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(session.intensity.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.type.displayName)
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.label)
                    HStack(spacing: 6) {
                        Text(session.intensity.displayName.uppercased())
                            .font(.caption2.weight(.semibold))
                            .tracking(0.6)
                            .foregroundStyle(session.intensity.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(session.intensity.color.opacity(0.14))
                            )
                        Text(session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                            .font(.caption2)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)

            Rectangle()
                .fill(session.intensity.color.opacity(0.15))
                .frame(height: 0.5)

            // Input rows — no section label, no inner card background.
            // Just clean rows inside the same visual block as the header.
            VStack(spacing: Theme.Spacing.sm) {
                if !isStrengthSession {
                    inlineInputRow(
                        label: "Distance",
                        icon: "point.topleft.down.to.point.bottomright.curvepath",
                        iconColor: Theme.Colors.primary,
                        isFocused: focusedField == .distance,
                        diffChip: { diffChipDistance },
                        content: { distanceControl }
                    )
                }
                inlineInputRow(
                    label: "Duration",
                    icon: "clock",
                    iconColor: Theme.Colors.zone3,
                    isFocused: false,
                    diffChip: { diffChipDuration },
                    content: { durationControl }
                )
                if !isStrengthSession {
                    inlineInputRow(
                        label: "Elevation",
                        icon: "mountain.2.fill",
                        iconColor: Theme.Colors.success,
                        isFocused: focusedField == .elevation,
                        diffChip: { diffChipElevation },
                        content: { elevationControl }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(LinearGradient(
                    colors: [
                        session.intensity.color.opacity(colorScheme == .dark ? 0.14 : 0.06),
                        session.intensity.color.opacity(colorScheme == .dark ? 0.03 : 0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(session.intensity.color.opacity(0.22), lineWidth: 0.75)
        )
    }

    /// Input row used inside the unified card. Minimal: icon + label +
    /// control, plus an optional diff chip that appears only when the
    /// athlete has edited away from the planned value.
    @ViewBuilder
    private func inlineInputRow<Control: View, Chip: View>(
        label: String,
        icon: String,
        iconColor: Color,
        isFocused: Bool,
        @ViewBuilder diffChip: () -> Chip,
        @ViewBuilder content: () -> Control
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
                    .frame(width: 22)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: Theme.Spacing.sm)

                content()
                    .frame(width: Self.statsControlWidth, alignment: .trailing)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(isFocused
                        ? Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.08 : 0.04)
                        : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(isFocused ? Theme.Colors.warmCoral.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.2), value: isFocused)

            diffChip()
        }
    }

    // MARK: - Control views

    private var distanceControl: some View {
        HStack(spacing: 4) {
            Spacer(minLength: 0)
            TextField("0.0", text: $distanceText)
                .keyboardType(.decimalPad)
                .font(.title3.bold().monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($focusedField, equals: .distance)
            Text("km")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 38, alignment: .leading)
        }
    }

    private var durationControl: some View {
        HStack(spacing: 2) {
            Spacer(minLength: 0)
            durationPicker(value: $hours, label: "h", range: 0..<24)
            Text(":").font(.subheadline.bold()).foregroundStyle(Theme.Colors.tertiaryLabel)
            durationPicker(value: $minutes, label: "m", range: 0..<60)
            Text(":").font(.subheadline.bold()).foregroundStyle(Theme.Colors.tertiaryLabel)
            durationPicker(value: $seconds, label: "s", range: 0..<60)
        }
    }

    private var elevationControl: some View {
        HStack(spacing: 4) {
            Spacer(minLength: 0)
            TextField("0", text: $elevationText)
                .keyboardType(.numberPad)
                .font(.title3.bold().monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($focusedField, equals: .elevation)
            Text("m D+")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 38, alignment: .leading)
        }
    }

    // MARK: - Diff chips (per-row)

    @ViewBuilder
    private var diffChipDistance: some View {
        if session.plannedDistanceKm > 0,
           let entered = Double(distanceText.replacingOccurrences(of: ",", with: ".")),
           entered > 0 {
            let diff = entered - session.plannedDistanceKm
            let ratio = abs(diff) / session.plannedDistanceKm
            if ratio >= 0.02 {
                let sign = diff > 0 ? "+" : "−"
                diffCapsule(text: "\(sign)\(String(format: "%.1f", abs(diff))) km vs plan", ratio: ratio)
            }
        }
    }

    @ViewBuilder
    private var diffChipDuration: some View {
        if session.plannedDuration > 0 {
            let currentSeconds = hours * 3600 + minutes * 60 + seconds
            let plannedSeconds = Int(session.plannedDuration)
            if currentSeconds > 0 {
                let diff = currentSeconds - plannedSeconds
                let ratio = abs(Double(diff)) / Double(plannedSeconds)
                if ratio >= 0.02 {
                    let sign = diff > 0 ? "+" : "−"
                    diffCapsule(text: "\(sign)\(formatDurationDelta(abs(diff))) vs plan", ratio: ratio)
                }
            }
        }
    }

    @ViewBuilder
    private var diffChipElevation: some View {
        if session.plannedElevationGainM > 0,
           let entered = Double(elevationText),
           entered > 0 {
            let diff = entered - session.plannedElevationGainM
            let ratio = abs(diff) / session.plannedElevationGainM
            if ratio >= 0.02 {
                let sign = diff > 0 ? "+" : "−"
                diffCapsule(text: "\(sign)\(Int(abs(diff))) m vs plan", ratio: ratio)
            }
        }
    }

    // MARK: - Formatting helpers

    private var formatPlannedDuration: String {
        let total = Int(session.plannedDuration)
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(m)min"
    }

    // MARK: - Stats Entry

    /// Fixed width reserved for the right-side control in every stats row.
    /// Duration's 3 pickers + 2 colons need ≈ 148pt; we align distance and
    /// elevation to match so all three rows land on the same trailing edge
    /// and the cards visually balance.
    private static let statsControlWidth: CGFloat = 148

    private func durationPicker(value: Binding<Int>, label: String, range: Range<Int>) -> some View {
        Picker(label, selection: value) {
            ForEach(range, id: \.self) { v in
                Text(String(format: "%02d", v)).tag(v)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .fixedSize()
    }

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.Colors.warmCoral)
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, Theme.Spacing.xs)
    }

    // MARK: - Feeling

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("How Did It Feel?", icon: "face.smiling")

            HStack(spacing: 6) {
                ForEach(PerceivedFeeling.allCases, id: \.self) { f in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            feeling = feeling == f ? nil : f
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(emoji(for: f))
                                .font(.title3)
                            Text(feelingLabel(for: f))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xs + 2)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(feeling == f
                                    ? Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.2 : 0.1)
                                    : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(feeling == f ? Theme.Colors.warmCoral : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
    }

    // MARK: - RPE

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("Rate Your Effort", icon: "flame")

            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            rpe = rpe == value ? nil : value
                        }
                    } label: {
                        Text("\(value)")
                            .font(.caption.bold().monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(rpe == value ? rpeColor(value) : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6)))
                            )
                            .foregroundStyle(rpe == value ? .white : Theme.Colors.label)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("Easy").font(.caption2).foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text("Maximum").font(.caption2).foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
    }

    // MARK: - Complete Button

    /// Ready = at least one meaningful value has been entered. While the
    /// page is still blank the button dims and the pulse aura is hidden
    /// so it doesn't beckon before there's anything to submit.
    private var isReadyToSubmit: Bool {
        let hasDistance = Double(distanceText.replacingOccurrences(of: ",", with: ".")) ?? 0 > 0
        let hasDuration = hours * 3600 + minutes * 60 + seconds > 0
        let hasElevation = Double(elevationText) ?? 0 > 0
        let hasFeeling = feeling != nil || rpe != nil
        return hasDistance || hasDuration || hasElevation || hasFeeling
    }

    private var completeButton: some View {
        let ready = isReadyToSubmit
        return Button {
            let dist = Double(distanceText.replacingOccurrences(of: ",", with: "."))
            let dur: TimeInterval? = {
                let total = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                return total > 0 ? total : nil
            }()
            let elev = Double(elevationText)
            onComplete(dist, dur, elev, feeling, rpe)
        } label: {
            Label(hideFeelingAndRPE ? "Continue" : "Complete Session", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(.white)
                .background(Theme.Gradients.warmCoralCTA)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Theme.Colors.warmCoral.opacity(
                    ready ? (pulseOn ? 0.45 : 0.20) : 0.0
                ), radius: ready ? (pulseOn ? 12 : 6) : 0, y: 3)
                .opacity(ready ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!ready)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Diff capsule

    /// Tinted diff capsule for off-plan values. Colour escalates from
    /// neutral (<5% drift) through secondary grey (<15%) to warning
    /// amber beyond. Centered under the row so it doesn't float awkwardly.
    private func diffCapsule(text: String, ratio: Double) -> some View {
        let color = statusChipColor(ratio: ratio)
        return Text(text)
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(color.opacity(colorScheme == .dark ? 0.16 : 0.10))
            )
            .overlay(
                Capsule().stroke(color.opacity(0.28), lineWidth: 0.5)
            )
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func statusChipColor(ratio: Double) -> Color {
        if ratio < 0.05 { return Theme.Colors.success }
        if ratio < 0.15 { return Theme.Colors.secondaryLabel }
        return Theme.Colors.warning
    }

    private func formatDurationDelta(_ seconds: Int) -> String {
        if seconds >= 60 {
            let m = seconds / 60
            let s = seconds % 60
            return s > 0 ? "\(m)m\(s)s" : "\(m)min"
        }
        return "\(seconds)s"
    }

    // MARK: - Rationale card

    /// Short session-type-specific rationale card rendered below the
    /// Continue button. Fills the vertical space the page was wasting
    /// with something that pays the athlete back: a one-sentence
    /// "why this session" explanation written in a positive coaching
    /// tone. No data entry demanded, no chrome — just context.
    private var rationaleCard: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: rationaleIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Colors.warmCoral)
                .frame(width: 24)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(rationaleTitle)
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.Colors.warmCoral)
                Text(rationaleBody)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(LinearGradient(
                    colors: [
                        Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.08 : 0.04),
                        Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.02 : 0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.warmCoral.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var rationaleIcon: String {
        switch session.type {
        case .intervals:            return "bolt.fill"
        case .tempo:                return "wave.3.right"
        case .longRun, .backToBack: return "road.lanes"
        case .recovery:             return "leaf.fill"
        case .verticalGain:         return "mountain.2.fill"
        case .strengthConditioning: return "dumbbell.fill"
        case .race:                 return "flag.checkered"
        default:                    return "figure.run"
        }
    }

    private var rationaleTitle: String {
        switch session.type {
        case .intervals:            return "WHY INTERVALS"
        case .tempo:                return "WHY TEMPO"
        case .longRun:              return "WHY THE LONG RUN"
        case .backToBack:           return "WHY BACK-TO-BACK"
        case .recovery:             return "WHY RECOVERY"
        case .verticalGain:         return "WHY VERTICAL"
        case .strengthConditioning: return "WHY STRENGTH"
        case .race:                 return "RACE DAY"
        default:                    return "TODAY'S SESSION"
        }
    }

    private var rationaleBody: String {
        switch session.type {
        case .intervals:
            return "Short fast reps develop your VO2max and neuromuscular sharpness — the engine ceiling that caps how fast you can sustain anything. Stay crisp; the recovery between reps is work too."
        case .tempo:
            return "Tempo sessions build sustainable race pace. Comfortably hard, not all-out — this is the effort you'll ride on race day."
        case .longRun:
            return "The long run builds the aerobic base everything else sits on. Time on feet matters more than speed — go easy, go long, trust the process."
        case .backToBack:
            return "Two long days stacked to teach the body to run on tired legs — the single best ultra-specific stimulus you can give yourself."
        case .recovery:
            return "Recovery is when the adaptation actually happens. Truly easy — if someone asked you a question you should be able to answer in full sentences."
        case .verticalGain:
            return "Vertical work builds climbing-specific strength. Let form dictate pace on the way up; power-hike the steep bits — that's the specificity."
        case .strengthConditioning:
            return "Strength work keeps the chassis strong through heavy training. Fewer injuries, better running economy. Worth every minute."
        case .race:
            return "Show up, execute the plan, trust the training. The work is already done."
        default:
            return "Every session in the plan has a purpose. Show up, stay consistent, trust the process."
        }
    }

    // MARK: - Week progress footer

    /// Clean progress strip: fixed-size 16pt dots alternating with
    /// flexible-width 2pt track rectangles. The rectangles use
    /// `frame(maxWidth: .infinity)` so the dots stay evenly spaced no
    /// matter how many sessions the week contains. Track segments
    /// take on the success colour from index 0 through the current
    /// position, neutral beyond — reads as a continuous progress bar.
    private func weekProgressFooter(_ progress: WeekProgress) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(0..<progress.totalSessions, id: \.self) { idx in
                    if idx > 0 {
                        Rectangle()
                            .fill(trackFill(leftIdx: idx - 1, progress: progress))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                    weekDot(state: dotState(idx: idx, progress: progress))
                }
            }
            .padding(.horizontal, 2)

            HStack(spacing: 6) {
                Text("Session \(progress.currentSessionIndex + 1) of \(progress.totalSessions)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
                Text("·")
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                Text(progress.phaseLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
    }

    private enum DotState { case completed, current, upcoming }

    private func dotState(idx: Int, progress: WeekProgress) -> DotState {
        if idx == progress.currentSessionIndex { return .current }
        if idx < progress.completedBefore { return .completed }
        return .upcoming
    }

    /// Segment fill between dot[leftIdx] and dot[leftIdx+1]. Green when
    /// the segment's right endpoint is still within the "done + current"
    /// range (so the track fills progressively up to the current dot);
    /// neutral afterward.
    private func trackFill(leftIdx: Int, progress: WeekProgress) -> Color {
        let rightIdx = leftIdx + 1
        let isFilled = rightIdx <= max(progress.completedBefore, progress.currentSessionIndex)
        return isFilled
            ? Theme.Colors.success.opacity(0.55)
            : Theme.Colors.tertiaryLabel.opacity(0.25)
    }

    @ViewBuilder
    private func weekDot(state: DotState) -> some View {
        ZStack {
            switch state {
            case .completed:
                Circle()
                    .fill(Theme.Colors.success)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                    )
            case .current:
                Circle()
                    .fill(LinearGradient(
                        colors: [Theme.Colors.warmCoral, Theme.Colors.warmCoral.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.65), lineWidth: 1.5)
                    )
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.35), radius: 5)
            case .upcoming:
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(Theme.Colors.tertiaryLabel.opacity(0.35), lineWidth: 1.2)
                    )
            }
        }
    }

    // MARK: - Helpers

    private func emoji(for f: PerceivedFeeling) -> String {
        switch f { case .great: "😀"; case .good: "🙂"; case .ok: "😐"; case .tough: "😤"; case .terrible: "😫" }
    }

    private func feelingLabel(for f: PerceivedFeeling) -> String {
        switch f { case .great: "Great"; case .good: "Good"; case .ok: "OK"; case .tough: "Tough"; case .terrible: "Terrible" }
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value { case 1...3: Theme.Colors.success; case 4...6: Theme.Colors.warning; case 7...8: .orange; default: Theme.Colors.danger }
    }
}

// MARK: - Sync App Picker Page

private struct SyncAppPickerPage: View {
    @Environment(\.colorScheme) private var colorScheme
    let session: TrainingSession
    let recentRuns: [CompletedRun]
    var recentRunsProvider: ((Date) async -> [CompletedRun])?
    var stravaActivitiesProvider: ((Date) async -> [StravaActivity])?
    let onLinkRun: (UUID) -> Void
    let onLinkStravaActivity: (StravaActivity) -> Void

    @State private var selectedApp: SyncApp?

    enum SyncApp: String, Identifiable {
        case strava, garmin, coros, suunto, inApp
        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Choose your source")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // In-App runs
                syncAppButton(
                    title: "In-App Runs",
                    subtitle: "Runs recorded in UltraTrain",
                    icon: "figure.run",
                    iconColor: Theme.Colors.primary,
                    isAvailable: true,
                    app: .inApp
                )

                // Strava
                syncAppButton(
                    title: "Strava",
                    subtitle: stravaActivitiesProvider != nil ? "Connected" : "Connect to import activities",
                    icon: "figure.run",
                    iconColor: .orange,
                    isAvailable: stravaActivitiesProvider != nil,
                    app: .strava
                )

                // Coming soon apps
                syncAppButton(
                    title: "Garmin Connect",
                    subtitle: "Coming soon",
                    icon: "applewatch",
                    iconColor: .blue,
                    isAvailable: false,
                    app: .garmin
                )

                syncAppButton(
                    title: "COROS",
                    subtitle: "Coming soon",
                    icon: "applewatch",
                    iconColor: .teal,
                    isAvailable: false,
                    app: .coros
                )

                syncAppButton(
                    title: "Suunto",
                    subtitle: "Coming soon",
                    icon: "applewatch",
                    iconColor: .red,
                    isAvailable: false,
                    app: .suunto
                )
            }
            .padding()
        }
        .navigationTitle("Sync from App")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedApp) { app in
            switch app {
            case .strava:
                SyncActivityListPage(
                    title: "Strava Activities",
                    session: session,
                    stravaProvider: stravaActivitiesProvider,
                    onLinkStrava: onLinkStravaActivity
                )
            case .inApp:
                InAppRunListPage(
                    session: session,
                    recentRuns: recentRuns,
                    recentRunsProvider: recentRunsProvider,
                    onLinkRun: onLinkRun
                )
            default:
                EmptyView()
            }
        }
    }

    private func syncAppButton(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isAvailable: Bool,
        app: SyncApp
    ) -> some View {
        Button {
            guard isAvailable else { return }
            selectedApp = app
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isAvailable ? iconColor : Theme.Colors.tertiaryLabel)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconColor.opacity(isAvailable ? 0.12 : 0.05))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isAvailable ? Theme.Colors.label : Theme.Colors.tertiaryLabel)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(isAvailable ? Theme.Colors.secondaryLabel : Theme.Colors.tertiaryLabel)
                }

                Spacer()

                if !isAvailable {
                    Text("Soon")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Theme.Colors.tertiaryLabel.opacity(0.1)))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
            }
            .padding(Theme.Spacing.md)
            .futuristicGlassStyle()
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}

// MARK: - Strava Activity List Page

private struct SyncActivityListPage: View {
    let title: String
    let session: TrainingSession
    var stravaProvider: ((Date) async -> [StravaActivity])?
    let onLinkStrava: (StravaActivity) -> Void

    @State private var activities: [StravaActivity] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading activities...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if activities.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text("No recent activities found")
                        .font(.headline)
                    Text("Activities from the last 3 weeks will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(activities) { activity in
                    Button {
                        onLinkStrava(activity)
                    } label: {
                        activityRow(activity)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let provider = stravaProvider {
                activities = await provider(session.date)
            }
            isLoading = false
        }
    }

    private func activityRow(_ activity: StravaActivity) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "figure.run")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange))

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: Theme.Spacing.xs) {
                    Text(activity.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    if activity.distanceKm > 0 {
                        Text("\u{00B7}")
                        Text(String(format: "%.1f km", activity.distanceKm))
                    }
                    if activity.totalElevationGain > 0 {
                        Text("\u{00B7}")
                        Text(String(format: "%.0fm D+", activity.totalElevationGain))
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Image(systemName: "link.badge.plus")
                .foregroundStyle(Color.orange)
        }
    }
}

// MARK: - In-App Run List Page

private struct InAppRunListPage: View {
    let session: TrainingSession
    let recentRuns: [CompletedRun]
    var recentRunsProvider: ((Date) async -> [CompletedRun])?
    let onLinkRun: (UUID) -> Void

    @State private var loadedRuns: [CompletedRun]?

    private var runs: [CompletedRun] {
        loadedRuns ?? recentRuns
    }

    var body: some View {
        Group {
            if runs.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "figure.run.circle")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text("No in-app runs found")
                        .font(.headline)
                    Text("Record a run in the app, then come back to link it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(runs) { run in
                    Button {
                        onLinkRun(run.id)
                    } label: {
                        runRow(run)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("In-App Runs")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let provider = recentRunsProvider {
                loadedRuns = await provider(session.date)
            }
        }
    }

    private func runRow(_ run: CompletedRun) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "figure.run")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.Colors.primary))

            VStack(alignment: .leading, spacing: 2) {
                Text(run.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: Theme.Spacing.xs) {
                    Text(formatDuration(run.duration))
                    if run.distanceKm > 0 {
                        Text("\u{00B7}")
                        Text(String(format: "%.1f km", run.distanceKm))
                    }
                    if run.elevationGainM > 0 {
                        Text("\u{00B7}")
                        Text(String(format: "%.0fm D+", run.elevationGainM))
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Image(systemName: "link.badge.plus")
                .foregroundStyle(Theme.Colors.accentColor)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(minutes)min"
    }
}
