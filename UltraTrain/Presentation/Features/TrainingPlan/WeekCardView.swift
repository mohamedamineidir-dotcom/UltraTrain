import SwiftUI

struct WeekCardView: View {
    @Environment(\.unitPreference) private var units
    @State private var currentWeekPulse = false
    let week: TrainingWeek
    let weekIndex: Int
    let planStartDate: Date
    let planEndDate: Date
    let allWeeks: [TrainingWeek]
    let athlete: Athlete?
    let nutritionAdvisor: any SessionNutritionAdvisor
    let nutritionPreferences: NutritionPreferences
    let onToggleSession: (Int) -> Void
    let onSkipSession: (Int) -> Void
    let onUnskipSession: (Int) -> Void
    let onRescheduleSession: (Int, Date) -> Void
    let onSwapSession: (Int, SwapCandidate) -> Void
    let onReorderSession: (Int, Int, SwapCandidate) -> Void
    var workouts: [IntervalWorkout] = []
    var onValidateSession: ((Int) -> Void)?
    var onValidateSessionWithStats: ((Int, Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void)?
    var onLinkSessionToRun: ((Int, UUID) -> Void)?
    var recentRunsProvider: ((Date) async -> [CompletedRun])?
    var stravaActivitiesProvider: ((Date) async -> [StravaActivity])?
    var onLinkStravaActivity: ((Int, StravaActivity) -> Void)?

    @State private var isExpanded: Bool
    @State private var contextRescheduleItem: ContextSheetItem?
    @State private var contextSwapItem: ContextSheetItem?
    @State private var validateItem: ContextSheetItem?
    @State private var validateRecentRuns: [CompletedRun] = []

    init(
        week: TrainingWeek,
        weekIndex: Int,
        isCurrentWeek: Bool = false,
        planStartDate: Date,
        planEndDate: Date,
        allWeeks: [TrainingWeek],
        athlete: Athlete?,
        nutritionAdvisor: any SessionNutritionAdvisor,
        nutritionPreferences: NutritionPreferences,
        onToggleSession: @escaping (Int) -> Void,
        onSkipSession: @escaping (Int) -> Void,
        onUnskipSession: @escaping (Int) -> Void,
        onRescheduleSession: @escaping (Int, Date) -> Void,
        onSwapSession: @escaping (Int, SwapCandidate) -> Void,
        workouts: [IntervalWorkout] = [],
        onReorderSession: @escaping (Int, Int, SwapCandidate) -> Void,
        onValidateSession: ((Int) -> Void)? = nil,
        onValidateSessionWithStats: ((Int, Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void)? = nil,
        onLinkSessionToRun: ((Int, UUID) -> Void)? = nil,
        recentRunsProvider: ((Date) async -> [CompletedRun])? = nil,
        stravaActivitiesProvider: ((Date) async -> [StravaActivity])? = nil,
        onLinkStravaActivity: ((Int, StravaActivity) -> Void)? = nil
    ) {
        self.week = week
        self.weekIndex = weekIndex
        self.planStartDate = planStartDate
        self.planEndDate = planEndDate
        self.allWeeks = allWeeks
        self.athlete = athlete
        self.nutritionAdvisor = nutritionAdvisor
        self.nutritionPreferences = nutritionPreferences
        self.onToggleSession = onToggleSession
        self.onSkipSession = onSkipSession
        self.onUnskipSession = onUnskipSession
        self.onRescheduleSession = onRescheduleSession
        self.onSwapSession = onSwapSession
        self.workouts = workouts
        self.onReorderSession = onReorderSession
        self.onValidateSession = onValidateSession
        self.onValidateSessionWithStats = onValidateSessionWithStats
        self.onLinkSessionToRun = onLinkSessionToRun
        self.recentRunsProvider = recentRunsProvider
        self.stravaActivitiesProvider = stravaActivitiesProvider
        self.onLinkStravaActivity = onLinkStravaActivity
        _isExpanded = State(initialValue: isCurrentWeek)
    }

    private var isCurrentWeek: Bool {
        week.containsToday
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left phase accent border with gradient
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [phaseAccentColor.opacity(0.7), phaseAccentColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .shadow(color: phaseAccentColor.opacity(0.5), radius: 6, x: 3)

            VStack(alignment: .leading, spacing: 0) {
                headerButton
                weekProgressBar
                if isExpanded {
                    sessionsList
                }
            }
        }
        .futuristicGlassStyle(phaseTint: phaseAccentColor)
        .background(recoveryBackground)
        .overlay(currentWeekBorder)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .onAppear {
            if isCurrentWeek {
                withAnimation(.pulseGlow) { currentWeekPulse = true }
            }
        }
        .accessibilityIdentifier("trainingPlan.weekCard.\(week.weekNumber)")
    }

    @ViewBuilder
    private var currentWeekBorder: some View {
        if isCurrentWeek {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(
                    phaseAccentColor.opacity(currentWeekPulse ? 0.4 : 0.15),
                    lineWidth: 1.5
                )
        }
    }
}

// MARK: - Header

extension WeekCardView {

    private var headerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Line 1: Week N + phase badge + progress fraction
                HStack {
                    Text("Week \(week.weekNumber)")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.Colors.label)
                    Text(week.phase.displayName)
                        .font(.caption2.bold())
                        .foregroundStyle(phaseAccentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(phaseAccentColor.opacity(0.12))
                        .clipShape(Capsule())
                    if week.isRecoveryWeek {
                        Text(String(localized: "week.recovery", defaultValue: "Recovery"))
                            .font(.caption2)
                            .foregroundStyle(.mint)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.mint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text(progressText)
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .accessibilityHidden(true)
                }

                // Line 2: Date range
                Text(weekDateRange)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)

                // Line 3: Duration (primary) + Elevation
                HStack(spacing: Theme.Spacing.md) {
                    Label(formattedWeekDuration, systemImage: "clock")
                    Label(UnitFormatter.formatElevation(week.targetElevationGainM, unit: units), systemImage: "mountain.2.fill")
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(weekHeaderAccessibilityLabel)
        .accessibilityHint(isExpanded ? "Double-tap to collapse sessions" : "Double-tap to expand sessions")
        .accessibilityAddTraits(.isButton)
    }

    private var weekHeaderAccessibilityLabel: String {
        var label = "Week \(week.weekNumber), \(week.phase.displayName) phase"
        if week.isRecoveryWeek { label += ", recovery week" }
        label += ". \(formattedWeekDuration)"
        label += ", \(UnitFormatter.formatElevation(week.targetElevationGainM, unit: units)) elevation"
        label += ". \(progressText)"
        return label
    }

    private var formattedWeekDuration: String {
        let total = Int(week.targetDurationSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(hours)h"
        }
        return "\(minutes)min"
    }
}

// MARK: - Progress Bar

extension WeekCardView {

    private var weekProgressBar: some View {
        let active = week.sessions.filter { $0.type != .rest && $0.type != .strengthConditioning && !$0.isSkipped }
        let done = active.filter(\.isCompleted).count
        let fraction = active.isEmpty ? 0.0 : Double(done) / Double(active.count)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.secondaryLabel.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [phaseAccentColor.opacity(0.7), phaseAccentColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: phaseAccentColor.opacity(0.3), radius: 2, y: 0)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }
}

// MARK: - Sessions List

extension WeekCardView {

    /// Groups sessions by calendar day so same-day S&C + run appear together.
    private var dayGroupedSessions: [(day: Date, sessions: [(index: Int, session: TrainingSession)])] {
        var groups: [(day: Date, sessions: [(index: Int, session: TrainingSession)])] = []
        for (idx, session) in week.sessions.enumerated() {
            let day = Calendar.current.startOfDay(for: session.date)
            if let last = groups.last, last.day == day {
                groups[groups.count - 1].sessions.append((idx, session))
            } else {
                groups.append((day, [(idx, session)]))
            }
        }
        return groups
    }

    private var sessionsList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, Theme.Spacing.sm)

            ForEach(Array(dayGroupedSessions.enumerated()), id: \.offset) { groupIdx, dayGroup in
                if groupIdx > 0 {
                    Rectangle()
                        .fill(Theme.Colors.tertiaryLabel.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.leading, 48)
                }

                // Primary session for this day (first non-SC, or the only session)
                let primary = dayGroup.sessions.first(where: { $0.session.type != .strengthConditioning })
                    ?? dayGroup.sessions[0]
                let scSessions = dayGroup.sessions.filter { $0.session.type == .strengthConditioning }

                VStack(spacing: 0) {
                    sessionRow(primary.index, primary.session)

                    // Show S&C as compact sub-row under the primary session
                    ForEach(scSessions, id: \.session.id) { scItem in
                        scCompactRow(scItem.index, scItem.session)
                    }
                }
            }
        }
        .sheet(item: $contextRescheduleItem) { item in
            RescheduleDateSheet(
                currentDate: item.session.date,
                planStartDate: planStartDate,
                planEndDate: planEndDate,
                onReschedule: { newDate in onRescheduleSession(item.sessionIndex, newDate) }
            )
        }
        .sheet(item: $contextSwapItem) { item in
            SwapSessionSheet(
                currentSession: item.session,
                availableSessions: buildSwapCandidates(excluding: item.session),
                onSwap: { candidate in onSwapSession(item.sessionIndex, candidate) }
            )
        }
        .sheet(item: $validateItem) { item in
            SessionValidationView(
                session: item.session,
                recentRuns: validateRecentRuns,
                onComplete: { dist, dur, elev, feeling, exertion in
                    if dist != nil || dur != nil || elev != nil || feeling != nil || exertion != nil {
                        onValidateSessionWithStats?(item.sessionIndex, dist, dur, elev, feeling, exertion)
                    } else {
                        onValidateSession?(item.sessionIndex)
                    }
                },
                onLinkRun: { runId in
                    onLinkSessionToRun?(item.sessionIndex, runId)
                },
                recentRunsProvider: recentRunsProvider,
                stravaActivitiesProvider: stravaActivitiesProvider,
                onLinkStravaActivity: { activity in
                    onLinkStravaActivity?(item.sessionIndex, activity)
                }
            )
        }
    }

    private func sessionRow(_ sessionIndex: Int, _ session: TrainingSession) -> some View {
        NavigationLink(destination: sessionDetailView(for: session, at: sessionIndex)) {
            SessionRowView(session: session) {
                if !session.isCompleted && onValidateSession != nil {
                    Task {
                        validateRecentRuns = await recentRunsProvider?(session.date) ?? []
                        validateItem = ContextSheetItem(sessionIndex: sessionIndex, session: session)
                    }
                } else {
                    onToggleSession(sessionIndex)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu { sessionContextMenu(for: session, at: sessionIndex) }
        .draggable(SessionDragData(
            sessionId: session.id, weekIndex: weekIndex, sessionIndex: sessionIndex
        ))
        .dropDestination(for: SessionDragData.self) { items, _ in
            guard let source = items.first, source.sessionId != session.id else { return false }
            let target = SwapCandidate(session: session, weekIndex: weekIndex, sessionIndex: sessionIndex)
            onReorderSession(source.weekIndex, source.sessionIndex, target)
            return true
        }
        .accessibilityIdentifier("trainingPlan.sessionRow.\(sessionIndex)")
    }

    /// S&C shown as a small pill/chip attached below the primary session for that day.
    private func scCompactRow(_ sessionIndex: Int, _ session: TrainingSession) -> some View {
        NavigationLink(destination: sessionDetailView(for: session, at: sessionIndex)) {
            HStack(spacing: 6) {
                Spacer()
                    .frame(width: 44) // align with text after icon glow

                HStack(spacing: 5) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 9))
                    Text("+  S&C \u{00B7} \(Int(session.plannedDuration / 60))min")
                        .font(.caption2.weight(.medium))
                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.success)
                    }
                }
                .foregroundStyle(session.isCompleted ? Theme.Colors.success : .mint)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(
                        session.isCompleted ? Theme.Colors.success.opacity(0.1) : Color.mint.opacity(0.1)
                    )
                )
                .overlay(
                    Capsule().stroke(
                        session.isCompleted ? Theme.Colors.success.opacity(0.2) : Color.mint.opacity(0.15),
                        lineWidth: 0.5
                    )
                )

                Spacer()
            }
            .padding(.bottom, 4)
        }
        .buttonStyle(.plain)
        .contextMenu { sessionContextMenu(for: session, at: sessionIndex) }
        .accessibilityIdentifier("trainingPlan.scRow.\(sessionIndex)")
    }

    @ViewBuilder
    private func sessionContextMenu(for session: TrainingSession, at index: Int) -> some View {
        if !session.isCompleted && !session.isSkipped {
            if onValidateSession != nil {
                Button {
                    Task {
                        validateRecentRuns = await recentRunsProvider?(session.date) ?? []
                        validateItem = ContextSheetItem(sessionIndex: index, session: session)
                    }
                } label: {
                    Label("Validate Session", systemImage: "checkmark.circle.fill")
                }
            } else {
                Button { onToggleSession(index) } label: {
                    Label("Mark Complete", systemImage: "checkmark.circle")
                }
            }
            Button { onSkipSession(index) } label: {
                Label("Skip Session", systemImage: "forward.fill")
            }
            Button { contextRescheduleItem = ContextSheetItem(sessionIndex: index, session: session) } label: {
                Label("Reschedule", systemImage: "calendar")
            }
            Button { contextSwapItem = ContextSheetItem(sessionIndex: index, session: session) } label: {
                Label("Swap", systemImage: "arrow.triangle.swap")
            }
        } else if session.isSkipped {
            Button { onUnskipSession(index) } label: {
                Label("Unskip", systemImage: "arrow.uturn.backward")
            }
        } else if session.isCompleted {
            Button { onToggleSession(index) } label: {
                Label("Mark Incomplete", systemImage: "xmark.circle")
            }
        }
    }
}

// MARK: - Navigation & Data

extension WeekCardView {

    private func sessionDetailView(for session: TrainingSession, at sessionIndex: Int) -> SessionDetailView {
        let candidates = buildSwapCandidates(excluding: session)
        return SessionDetailView(
            session: session,
            planStartDate: planStartDate,
            planEndDate: planEndDate,
            swapCandidates: candidates,
            athlete: athlete,
            nutritionAdvisor: nutritionAdvisor,
            nutritionPreferences: nutritionPreferences,
            workouts: workouts,
            onSkip: { onSkipSession(sessionIndex) },
            onUnskip: session.isSkipped ? { onUnskipSession(sessionIndex) } : nil,
            onReschedule: { newDate in onRescheduleSession(sessionIndex, newDate) },
            onSwap: { candidate in onSwapSession(sessionIndex, candidate) },
            onValidate: onValidateSession != nil ? { onValidateSession?(sessionIndex) } : nil,
            onValidateWithStats: onValidateSessionWithStats != nil ? { dist, dur, elev, feeling, exertion in
                onValidateSessionWithStats?(sessionIndex, dist, dur, elev, feeling, exertion)
            } : nil,
            onLinkRun: onLinkSessionToRun != nil ? { runId in onLinkSessionToRun?(sessionIndex, runId) } : nil,
            recentRuns: validateRecentRuns
        )
    }

    private func buildSwapCandidates(excluding session: TrainingSession) -> [SwapCandidate] {
        var candidates: [SwapCandidate] = []
        for (wIdx, w) in allWeeks.enumerated() {
            for (sIdx, s) in w.sessions.enumerated() {
                if s.id != session.id && !s.isCompleted && !s.isSkipped && s.type != .rest {
                    candidates.append(SwapCandidate(session: s, weekIndex: wIdx, sessionIndex: sIdx))
                }
            }
        }
        return candidates
    }
}

// MARK: - Computed Properties

extension WeekCardView {

    private var progressText: String {
        // Only count running sessions, not S&C
        let runs = week.sessions.filter { $0.type != .rest && $0.type != .strengthConditioning && !$0.isSkipped }
        let done = runs.filter(\.isCompleted).count
        return "\(done)/\(runs.count)"
    }

    private var weekDateRange: String {
        guard let first = week.sessions.first, let last = week.sessions.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: first.date)) – \(formatter.string(from: last.date))"
    }

    private var phaseAccentColor: Color {
        week.phase.color
    }

    @ViewBuilder
    private var recoveryBackground: some View {
        if week.isRecoveryWeek {
            Color.mint.opacity(0.04)
        } else {
            Color.clear
        }
    }
}

// MARK: - Context Sheet Item

private struct ContextSheetItem: Identifiable {
    let id = UUID()
    let sessionIndex: Int
    let session: TrainingSession
}
