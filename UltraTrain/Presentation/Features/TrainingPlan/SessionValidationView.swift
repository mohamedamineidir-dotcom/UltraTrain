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
    /// The next running session in the week AFTER this one. Used to
    /// surface a forward-looking "Next up" card on the validation page.
    /// Nil when this is already the last session of the week.
    let nextSessionPreview: NextSessionPreview?
}

/// Lightweight snapshot of the week's next run session.
struct NextSessionPreview: Equatable, Sendable {
    let type: SessionType
    let date: Date
    let durationSeconds: TimeInterval
    let distanceKm: Double
    let intensity: Intensity
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
    @State private var stepIndex: Int = 0
    @FocusState private var focusedField: StatsField?

    enum StatsField: Hashable { case distance, elevation }

    /// Atomic step in the validation flow. The sequence is computed per
    /// session — intervals/tempo with a feedback context skip feeling/rpe
    /// here because IR-1 will capture them afterwards.
    fileprivate enum Step {
        case stats
        case feeling
        case rpe

        var title: String {
            switch self {
            case .stats:   return "Enter your stats"
            case .feeling: return "How did it feel?"
            case .rpe:     return "Rate your effort"
            }
        }

        var subtitle: String {
            switch self {
            case .stats:   return "Planned values are pre-filled — adjust anything that came out different."
            case .feeling: return "Overall impression from start to finish."
            case .rpe:     return "1 is walking-easy, 10 is the hardest effort you can imagine."
            }
        }

        var iconName: String {
            switch self {
            case .stats:   return "stopwatch.fill"
            case .feeling: return "face.smiling"
            case .rpe:     return "flame.fill"
            }
        }
    }

    private var steps: [Step] {
        var s: [Step] = [.stats]
        if !hideFeelingAndRPE {
            s.append(.feeling)
            s.append(.rpe)
        }
        return s
    }

    private var currentStep: Step { steps[stepIndex] }
    private var isLastStep: Bool { stepIndex == steps.count - 1 }

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
        VStack(spacing: 0) {
            if steps.count > 1 {
                progressBar
            }
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    stepHeader
                    stepContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                    // Context + forward-looking cards sit on the final
                    // step only so they read as "what happens after you
                    // submit" rather than filler on every page.
                    if isLastStep {
                        rationaleCard
                        if let next = weekProgress?.nextSessionPreview {
                            nextUpCard(next)
                        }
                        if let progress = weekProgress {
                            weekProgressFooter(progress)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            navigationBar
            skipLink
        }
        .navigationTitle("Validate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseOn = true
            }
        }
    }

    // MARK: - Step chrome

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.tertiaryLabel.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(
                        colors: [session.intensity.color, session.intensity.color.opacity(0.75)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(steps.count))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.xs)
    }

    /// Shown on steps 2+ only. The stats step already carries a session-
    /// context header inside `unifiedSessionCard`, so repeating a titled
    /// step header above it would double up.
    @ViewBuilder
    private var stepHeader: some View {
        if currentStep != .stats {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: currentStep.iconName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(
                        LinearGradient(
                            colors: [session.intensity.color, session.intensity.color.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ))
                    .shadow(color: session.intensity.color.opacity(0.3), radius: 8, y: 4)
                Text(currentStep.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(currentStep.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.md)
            .id(currentStep.title)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case .stats:   unifiedSessionCard
            case .feeling: feelingSection
            case .rpe:     rpeSection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: stepIndex)
    }

    private var navigationBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if stepIndex > 0 {
                Button {
                    withAnimation { stepIndex -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm + 2)
                }
                .buttonStyle(.bordered)
                .tint(Theme.Colors.secondaryLabel)
                .accessibilityIdentifier("trainingPlan.validate.back")
            }

            Button {
                if isLastStep {
                    submit()
                } else {
                    withAnimation { stepIndex += 1 }
                }
            } label: {
                Label(
                    isLastStep ? (hideFeelingAndRPE ? "Continue" : "Complete Session")
                               : "Continue",
                    systemImage: isLastStep ? "checkmark.circle.fill" : "chevron.right"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .foregroundStyle(.white)
                .background(Theme.Gradients.warmCoralCTA)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .shadow(
                    color: Theme.Colors.warmCoral.opacity(isLastStep && pulseOn ? 0.45 : 0.25),
                    radius: isLastStep && pulseOn ? 12 : 6,
                    y: 3
                )
                .opacity(isLastStep && !isReadyToSubmit ? 0.55 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(isLastStep && !isReadyToSubmit)
            .accessibilityIdentifier(isLastStep ? "trainingPlan.validate.complete" : "trainingPlan.validate.continue")
            .accessibilityHint(isLastStep ? "Submit your session stats" : "Move to the next step")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.regularMaterial)
    }

    private var skipLink: some View {
        Button {
            onComplete(nil, nil, nil, nil, nil)
        } label: {
            Text("Skip stats, just mark complete")
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
        .padding(.bottom, Theme.Spacing.xs)
        .padding(.top, 2)
        .accessibilityIdentifier("trainingPlan.validate.skipStats")
        .accessibilityHint("Mark session complete without entering any stats")
    }

    private func submit() {
        let dist = Double(distanceText.replacingOccurrences(of: ",", with: "."))
        let dur: TimeInterval? = {
            let total = TimeInterval(hours * 3600 + minutes * 60 + seconds)
            return total > 0 ? total : nil
        }()
        let elev = Double(elevationText)
        onComplete(dist, dur, elev, feeling, rpe)
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
        .background(tintedGlass(tint: session.intensity.color))
        .overlay(tintedGlassBorder(tint: session.intensity.color))
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

    // MARK: - Tinted glass background

    /// Builds a three-layer card background: a diagonal tint gradient
    /// (gives each card its colour identity), a top-left white sheen
    /// (the "glass" highlight that makes the page feel less flat), and
    /// a hairline tinted border. Applied to every card on the page
    /// with a different tint per card so the layout carries visual
    /// variety without being flashy.
    @ViewBuilder
    private func tintedGlass(tint: Color, corner: CGFloat = Theme.CornerRadius.lg) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(LinearGradient(
                    colors: [
                        tint.opacity(colorScheme == .dark ? 0.22 : 0.11),
                        tint.opacity(colorScheme == .dark ? 0.05 : 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            RoundedRectangle(cornerRadius: corner)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.10 : 0.45), location: 0.0),
                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.02 : 0.10), location: 0.30),
                        .init(color: Color.clear, location: 0.60)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .allowsHitTesting(false)
        }
    }

    private func tintedGlassBorder(tint: Color, corner: CGFloat = Theme.CornerRadius.lg) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .stroke(tint.opacity(0.25), lineWidth: 0.75)
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
                    .accessibilityLabel(feelingLabel(for: f))
                    .accessibilityAddTraits(feeling == f ? .isSelected : [])
                    .accessibilityIdentifier("trainingPlan.validate.feeling.\(f.rawValue)")
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
                    .accessibilityLabel("RPE \(value) of 10")
                    .accessibilityAddTraits(rpe == value ? .isSelected : [])
                    .accessibilityIdentifier("trainingPlan.validate.rpe.\(value)")
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
        .background(tintedGlass(tint: Theme.Colors.warmCoral, corner: Theme.CornerRadius.md))
        .overlay(tintedGlassBorder(tint: Theme.Colors.warmCoral, corner: Theme.CornerRadius.md))
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
            return "Short fast reps push your VO2max ceiling. The recovery between reps is part of the work."
        case .tempo:
            return "This is race-pace sustainability work. Comfortably hard, not all-out."
        case .longRun:
            return "Time on feet builds the aerobic base everything else sits on. Easy and long wins."
        case .backToBack:
            return "Two long days stacked trains your legs to run tired. Core ultra-specific stimulus."
        case .recovery:
            return "Adaptation happens when you recover, not when you train. Keep it genuinely easy."
        case .verticalGain:
            return "Climbing-specific strength. Power-hike the steep stuff; that's the specificity."
        case .strengthConditioning:
            return "Keeps the chassis strong through heavy weeks. Fewer injuries, better economy."
        case .race:
            return "Execute the plan. Trust the training."
        default:
            return "Every session has a purpose. Stay consistent."
        }
    }

    // MARK: - Next up card

    /// Forward-looking card showing the next run session in the same
    /// week. Fills the remaining page space with context the athlete
    /// earns by completing this one, and is deliberately distinct from
    /// what the per-rep feedback page will ask (pace, RPE, completion,
    /// notes) so it doesn't pre-empt that flow.
    private func nextUpCard(_ next: NextSessionPreview) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(next.intensity.color.opacity(colorScheme == .dark ? 0.28 : 0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: next.type.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(next.intensity.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("NEXT UP")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                HStack(spacing: 6) {
                    Text(next.type.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.label)
                    Text("·").foregroundStyle(Theme.Colors.tertiaryLabel)
                    Text(next.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Text(nextUpSummary(next))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tintedGlass(tint: next.intensity.color, corner: Theme.CornerRadius.md))
        .overlay(tintedGlassBorder(tint: next.intensity.color, corner: Theme.CornerRadius.md))
    }

    private func nextUpSummary(_ next: NextSessionPreview) -> String {
        var parts: [String] = []
        if next.durationSeconds > 0 {
            let total = Int(next.durationSeconds)
            let h = total / 3600
            let m = (total % 3600) / 60
            parts.append(h > 0
                         ? (m > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(h)h")
                         : "\(m) min")
        }
        if next.distanceKm > 0 {
            parts.append(String(format: "%.1f km", next.distanceKm))
        }
        parts.append(next.intensity.displayName)
        return parts.joined(separator: " · ")
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
        .background(tintedGlass(tint: Theme.Colors.success, corner: Theme.CornerRadius.md))
        .overlay(tintedGlassBorder(tint: Theme.Colors.success, corner: Theme.CornerRadius.md))
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
