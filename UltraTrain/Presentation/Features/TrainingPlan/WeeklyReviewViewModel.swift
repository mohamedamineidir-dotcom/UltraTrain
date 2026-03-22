import Foundation

@Observable @MainActor
final class WeeklyReviewViewModel {

    enum Phase: Equatable {
        case question
        case sessionPicker
        case loading
        case done
    }

    var phase: Phase = .question
    var nonRestSessions: [TrainingSession]
    var selectedCompletedIds: Set<UUID> = []

    let previousWeekIndex: Int
    let previousWeekNumber: Int

    private let planRepository: any TrainingPlanRepository
    private var plan: TrainingPlan

    init(
        planRepository: any TrainingPlanRepository,
        plan: TrainingPlan,
        previousWeekIndex: Int,
        previousWeekNumber: Int,
        nonRestSessions: [TrainingSession]
    ) {
        self.planRepository = planRepository
        self.plan = plan
        self.previousWeekIndex = previousWeekIndex
        self.previousWeekNumber = previousWeekNumber
        self.nonRestSessions = nonRestSessions
    }

    // MARK: - Actions

    func handleAllCompleted() async {
        let result = WeeklyReviewHandler.applyOutcome(
            .allCompleted,
            plan: plan,
            previousWeekIndex: previousWeekIndex
        )
        await persistSessions(result.updatedSessions)
        phase = .loading
    }

    func handleNoneCompleted() async {
        let result = WeeklyReviewHandler.applyOutcome(
            .noneCompleted,
            plan: plan,
            previousWeekIndex: previousWeekIndex
        )
        await persistSessions(result.updatedSessions)

        if result.needsVolumeReduction, let cwi = plan.currentWeekIndex {
            let reduced = WeeklyReviewHandler.reduceCurrentWeekVolume(
                plan: plan,
                currentWeekIndex: cwi
            )
            await persistSessions(reduced)
        }

        phase = .loading
    }

    func showSessionPicker() {
        phase = .sessionPicker
    }

    func handlePartialCompleted() async {
        let result = WeeklyReviewHandler.applyOutcome(
            .partiallyCompleted(completedIds: selectedCompletedIds),
            plan: plan,
            previousWeekIndex: previousWeekIndex
        )
        await persistSessions(result.updatedSessions)

        if result.needsVolumeReduction, let cwi = plan.currentWeekIndex {
            let reduced = WeeklyReviewHandler.reduceCurrentWeekVolume(
                plan: plan,
                currentWeekIndex: cwi
            )
            await persistSessions(reduced)
        }

        phase = .loading
    }

    func onLoadingComplete() {
        phase = .done
    }

    // MARK: - Persistence

    private func persistSessions(_ sessions: [TrainingSession]) async {
        for session in sessions {
            try? await planRepository.updateSession(session)
        }
    }
}
