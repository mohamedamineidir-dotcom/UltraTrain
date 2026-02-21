import Foundation
import os

@Observable
@MainActor
final class TrainingCalendarViewModel {
    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository

    var plan: TrainingPlan?
    var completedRuns: [CompletedRun] = []
    var displayedMonth: Date = Date.now.startOfMonth
    var selectedDate: Date?
    var isLoading = false
    var error: String?

    init(
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            plan = try await planRepository.getActivePlan()
            guard let athlete = try await athleteRepository.getAthlete() else { return }
            completedRuns = try await runRepository.getRuns(for: athlete.id)
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load training calendar: \(error)")
        }
    }

    func navigateMonth(by offset: Int) {
        displayedMonth = displayedMonth.adding(months: offset)
    }

    func phaseForDate(_ date: Date) -> TrainingPhase? {
        guard let plan else { return nil }
        return plan.weeks.first { week in
            date >= week.startDate.startOfDay && date <= week.endDate.startOfDay
        }?.phase
    }

    func sessionsForDate(_ date: Date) -> [TrainingSession] {
        guard let plan else { return [] }
        return plan.weeks
            .flatMap(\.sessions)
            .filter { $0.date.isSameDay(as: date) }
    }

    func runsForDate(_ date: Date) -> [CompletedRun] {
        completedRuns.filter { $0.date.isSameDay(as: date) }
    }

    func dayStatus(_ date: Date) -> TrainingCalendarDayStatus {
        let sessions = sessionsForDate(date)
        let runs = runsForDate(date)
        let activeSessions = sessions.filter { $0.type != .rest }

        if activeSessions.isEmpty && runs.isEmpty {
            let restSessions = sessions.filter { $0.type == .rest }
            if !restSessions.isEmpty {
                return .rest
            }
            return .noActivity
        }

        if activeSessions.isEmpty && !runs.isEmpty {
            return .ranWithoutPlan
        }

        let completedCount = activeSessions.filter(\.isCompleted).count

        if completedCount == activeSessions.count {
            return .completed(sessionCount: completedCount)
        }

        if completedCount > 0 {
            return .partial(completed: completedCount, total: activeSessions.count)
        }

        return .planned(sessionCount: activeSessions.count)
    }
}
