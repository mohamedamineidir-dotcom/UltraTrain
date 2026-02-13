import Foundation
import os

@Observable
@MainActor
final class RunTrackingLaunchViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository

    // MARK: - State

    var athlete: Athlete?
    var todaysSessions: [TrainingSession] = []
    var selectedSession: TrainingSession?
    var isLoading = false
    var error: String?
    var showActiveRun = false

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository
    ) {
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.runRepository = runRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            athlete = try await athleteRepository.getAthlete()
            if let plan = try await planRepository.getActivePlan() {
                todaysSessions = extractTodaysSessions(from: plan)
            }
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to load run launch data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Session Selection

    func selectSession(_ session: TrainingSession?) {
        selectedSession = session
    }

    func startRun() {
        showActiveRun = true
    }

    // MARK: - Private

    private func extractTodaysSessions(from plan: TrainingPlan) -> [TrainingSession] {
        let calendar = Calendar.current
        let today = Date.now

        for week in plan.weeks {
            let sessions = week.sessions.filter { session in
                calendar.isDate(session.date, inSameDayAs: today)
                    && !session.isCompleted
                    && session.type != .rest
            }
            if !sessions.isEmpty { return sessions }
        }
        return []
    }
}
