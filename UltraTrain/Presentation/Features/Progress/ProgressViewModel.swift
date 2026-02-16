import Foundation
import os

struct WeeklyVolume: Identifiable, Equatable {
    let id: Date
    var weekStartDate: Date
    var distanceKm: Double
    var elevationGainM: Double
    var duration: TimeInterval
    var runCount: Int

    init(weekStartDate: Date, distanceKm: Double = 0, elevationGainM: Double = 0, duration: TimeInterval = 0, runCount: Int = 0) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.duration = duration
        self.runCount = runCount
    }
}

struct WeeklyAdherence: Identifiable, Equatable {
    let id: Date
    var weekStartDate: Date
    var weekNumber: Int
    var completed: Int
    var total: Int
    var percent: Double

    init(weekStartDate: Date, weekNumber: Int, completed: Int, total: Int) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.weekNumber = weekNumber
        self.completed = completed
        self.total = total
        self.percent = total > 0 ? Double(completed) / Double(total) * 100 : 0
    }
}

@Observable
@MainActor
final class ProgressViewModel {

    // MARK: - Dependencies

    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository

    // MARK: - State

    var weeklyVolumes: [WeeklyVolume] = []
    var weeklyAdherence: [WeeklyAdherence] = []
    var planAdherence: (completed: Int, total: Int) = (0, 0)
    var totalRuns = 0
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository
    ) {
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                isLoading = false
                return
            }

            let runs = try await runRepository.getRuns(for: athlete.id)
            totalRuns = runs.count
            weeklyVolumes = computeWeeklyVolumes(from: runs)

            if let plan = try await planRepository.getActivePlan() {
                planAdherence = computeAdherence(plan: plan)
                weeklyAdherence = computeWeeklyAdherence(plan: plan)
            }
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load progress: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed

    var totalDistanceKm: Double {
        weeklyVolumes.reduce(0) { $0 + $1.distanceKm }
    }

    var totalElevationGainM: Double {
        weeklyVolumes.reduce(0) { $0 + $1.elevationGainM }
    }

    var averageWeeklyKm: Double {
        let activeWeeks = weeklyVolumes.filter { $0.runCount > 0 }
        guard !activeWeeks.isEmpty else { return 0 }
        return activeWeeks.reduce(0) { $0 + $1.distanceKm } / Double(activeWeeks.count)
    }

    var adherencePercent: Double {
        guard planAdherence.total > 0 else { return 0 }
        return Double(planAdherence.completed) / Double(planAdherence.total) * 100
    }

    // MARK: - Private

    private func computeWeeklyVolumes(from runs: [CompletedRun]) -> [WeeklyVolume] {
        let calendar = Calendar.current
        let now = Date.now
        var volumes: [WeeklyVolume] = []

        for weeksAgo in (0..<8).reversed() {
            let weekStart = calendar.startOfDay(for: now.adding(weeks: -weeksAgo)).startOfWeek
            let weekEnd = weekStart.adding(days: 7)
            let weekRuns = runs.filter { $0.date >= weekStart && $0.date < weekEnd }

            volumes.append(WeeklyVolume(
                weekStartDate: weekStart,
                distanceKm: weekRuns.reduce(0) { $0 + $1.distanceKm },
                elevationGainM: weekRuns.reduce(0) { $0 + $1.elevationGainM },
                duration: weekRuns.reduce(0) { $0 + $1.duration },
                runCount: weekRuns.count
            ))
        }
        return volumes
    }

    private func computeAdherence(plan: TrainingPlan) -> (completed: Int, total: Int) {
        let allSessions = plan.weeks.flatMap(\.sessions)
        let active = allSessions.filter { $0.type != .rest }
        let completed = active.filter(\.isCompleted).count
        return (completed, active.count)
    }

    private func computeWeeklyAdherence(plan: TrainingPlan) -> [WeeklyAdherence] {
        let now = Date.now
        return plan.weeks
            .filter { $0.startDate <= now }
            .map { week in
                let active = week.sessions.filter { $0.type != .rest }
                let completed = active.filter(\.isCompleted).count
                return WeeklyAdherence(
                    weekStartDate: week.startDate,
                    weekNumber: week.weekNumber,
                    completed: completed,
                    total: active.count
                )
            }
    }
}
