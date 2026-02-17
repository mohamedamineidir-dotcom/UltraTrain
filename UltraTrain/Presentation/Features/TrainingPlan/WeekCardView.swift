import SwiftUI

struct WeekCardView: View {
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

    @State private var isExpanded: Bool

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
        onSwapSession: @escaping (Int, SwapCandidate) -> Void
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
                        Label("\(week.targetVolumeKm, specifier: "%.0f") km", systemImage: "figure.run")
                        Label("\(week.targetElevationGainM, specifier: "%.0f") m", systemImage: "mountain.2.fill")
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
            }
        }
        .buttonStyle(.plain)
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
                .accessibilityIdentifier("trainingPlan.sessionRow.\(sessionIndex)")
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
