import SwiftUI

struct WeekCardView: View {
    @Environment(\.unitPreference) private var units
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

    @State private var isExpanded: Bool
    @State private var contextRescheduleItem: ContextSheetItem?
    @State private var contextSwapItem: ContextSheetItem?

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
        onReorderSession: @escaping (Int, Int, SwapCandidate) -> Void
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
        self.onReorderSession = onReorderSession
        _isExpanded = State(initialValue: isCurrentWeek)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerButton
            if isExpanded {
                sessionsList
            }
        }
        .cardStyle()
        .accessibilityIdentifier("trainingPlan.weekCard.\(week.weekNumber)")
    }

    private var headerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Week \(week.weekNumber)")
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.label)
                        PhaseBadge(phase: week.phase)
                        if week.isRecoveryWeek {
                            Text("Recovery")
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: Theme.Spacing.md) {
                        Label(UnitFormatter.formatDistance(week.targetVolumeKm, unit: units, decimals: 0), systemImage: "figure.run")
                        Label("\(UnitFormatter.formatElevation(week.targetElevationGainM, unit: units))", systemImage: "mountain.2.fill")
                        Text(progressText)
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .accessibilityHidden(true)
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
        if week.isRecoveryWeek {
            label += ", recovery week"
        }
        label += ". \(UnitFormatter.formatDistance(week.targetVolumeKm, unit: units, decimals: 0))"
        label += ", \(UnitFormatter.formatElevation(week.targetElevationGainM, unit: units)) elevation"
        label += ". \(progressText)"
        return label
    }

    private var sessionsList: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, Theme.Spacing.sm)

            ForEach(Array(week.sessions.enumerated()), id: \.element.id) { sessionIndex, session in
                NavigationLink(destination: sessionDetailView(for: session, at: sessionIndex)) {
                    SessionRowView(session: session) {
                        onToggleSession(sessionIndex)
                    }
                }
                .buttonStyle(.plain)
                .contextMenu { sessionContextMenu(for: session, at: sessionIndex) }
                .draggable(SessionDragData(
                    sessionId: session.id,
                    weekIndex: weekIndex,
                    sessionIndex: sessionIndex
                ))
                .dropDestination(for: SessionDragData.self) { items, _ in
                    guard let source = items.first, source.sessionId != session.id else { return false }
                    let target = SwapCandidate(session: session, weekIndex: weekIndex, sessionIndex: sessionIndex)
                    onReorderSession(source.weekIndex, source.sessionIndex, target)
                    return true
                }
                .accessibilityIdentifier("trainingPlan.sessionRow.\(sessionIndex)")
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
    }

    @ViewBuilder
    private func sessionContextMenu(for session: TrainingSession, at index: Int) -> some View {
        if !session.isCompleted && !session.isSkipped {
            Button { onToggleSession(index) } label: {
                Label("Mark Complete", systemImage: "checkmark.circle")
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
            onSkip: { onSkipSession(sessionIndex) },
            onUnskip: session.isSkipped ? { onUnskipSession(sessionIndex) } : nil,
            onReschedule: { newDate in onRescheduleSession(sessionIndex, newDate) },
            onSwap: { candidate in onSwapSession(sessionIndex, candidate) }
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

    private var progressText: String {
        let active = week.sessions.filter { $0.type != .rest && !$0.isSkipped }
        let done = active.filter(\.isCompleted).count
        return "\(done)/\(active.count) done"
    }
}

private struct ContextSheetItem: Identifiable {
    let id = UUID()
    let sessionIndex: Int
    let session: TrainingSession
}
