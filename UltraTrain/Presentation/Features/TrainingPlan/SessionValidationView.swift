import SwiftUI

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
        onSaveIntervalFeedback: ((IntervalPerformanceFeedback) -> Void)? = nil
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
    let onComplete: (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void

    @State private var distanceText: String
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var elevationText: String
    @State private var feeling: PerceivedFeeling?
    @State private var rpe: Int?

    init(
        session: TrainingSession,
        hideFeelingAndRPE: Bool = false,
        onComplete: @escaping (Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void
    ) {
        self.session = session
        self.hideFeelingAndRPE = hideFeelingAndRPE
        self.onComplete = onComplete
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
                plannedTargetCard
                statsSection

                if !hideFeelingAndRPE {
                    feelingSection
                    rpeSection
                }

                completeButton

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
    }

    // MARK: - Planned Target

    private var plannedTargetCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            if !isStrengthSession && session.plannedDistanceKm > 0 {
                targetStat(
                    value: UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units, decimals: 1),
                    label: "Planned",
                    icon: "flag.checkered"
                )
            }
            if !isStrengthSession && session.plannedDistanceKm > 0 {
                divider
            }
            targetStat(
                value: formatPlannedDuration,
                label: "Target",
                icon: "stopwatch"
            )
            if !isStrengthSession && session.plannedElevationGainM > 0 {
                divider
                targetStat(
                    value: UnitFormatter.formatElevation(session.plannedElevationGainM, unit: units),
                    label: "D+",
                    icon: "arrow.up.right"
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(LinearGradient(
                    colors: [
                        session.intensity.color.opacity(colorScheme == .dark ? 0.18 : 0.09),
                        session.intensity.color.opacity(colorScheme == .dark ? 0.06 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(session.intensity.color.opacity(0.2), lineWidth: 0.75)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.Colors.tertiaryLabel.opacity(0.15))
            .frame(width: 1, height: 28)
    }

    private func targetStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(session.intensity.color)
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .tracking(0.5)
            }
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.Colors.label)
        }
        .frame(maxWidth: .infinity)
    }

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

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("Your Actual Stats", icon: "pencil.line")

            if !isStrengthSession {
                inputCard(label: "Distance", icon: "point.topleft.down.to.point.bottomright.curvepath", iconColor: Theme.Colors.primary) {
                    HStack(spacing: 4) {
                        Spacer(minLength: 0)
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .font(.title3.bold().monospacedDigit())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .frame(width: 38, alignment: .leading)
                    }
                }
            }

            inputCard(label: "Duration", icon: "clock", iconColor: Theme.Colors.zone3) {
                HStack(spacing: 2) {
                    Spacer(minLength: 0)
                    durationPicker(value: $hours, label: "h", range: 0..<24)
                    Text(":").font(.subheadline.bold()).foregroundStyle(Theme.Colors.tertiaryLabel)
                    durationPicker(value: $minutes, label: "m", range: 0..<60)
                    Text(":").font(.subheadline.bold()).foregroundStyle(Theme.Colors.tertiaryLabel)
                    durationPicker(value: $seconds, label: "s", range: 0..<60)
                }
            }

            if !isStrengthSession {
                inputCard(label: "Elevation", icon: "mountain.2.fill", iconColor: Theme.Colors.success) {
                    HStack(spacing: 4) {
                        Spacer(minLength: 0)
                        TextField("0", text: $elevationText)
                            .keyboardType(.numberPad)
                            .font(.title3.bold().monospacedDigit())
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("m D+")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                            .frame(width: 38, alignment: .leading)
                    }
                }
            }
        }
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
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

    private func inputCard<Content: View>(
        label: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: Theme.Spacing.sm)

            content()
                .frame(width: Self.statsControlWidth, alignment: .trailing)
        }
        .padding(.horizontal, Theme.Spacing.sm + 2)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6))
        )
    }

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

    private var completeButton: some View {
        Button {
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
                .shadow(color: Theme.Colors.warmCoral.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.top, Theme.Spacing.xs)
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
