import Foundation
import os

enum FitnessStatus: Equatable {
    case noData
    case optimal
    case injuryRisk
    case detraining
}

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Dependencies

    private let planRepository: any TrainingPlanRepository
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let fitnessRepository: any FitnessRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let raceRepository: any RaceRepository
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let finishEstimateRepository: any FinishEstimateRepository

    // MARK: - State

    var plan: TrainingPlan?
    var fitnessSnapshot: FitnessSnapshot?
    var fitnessHistory: [FitnessSnapshot] = []
    var runCount = 0
    var isLoading = false
    var fitnessError: String?
    var finishEstimate: FinishEstimate?
    var aRace: Race?
    var lastRun: CompletedRun?
    var upcomingRaces: [Race] = []

    // MARK: - Init

    init(
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        raceRepository: any RaceRepository,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        finishEstimateRepository: any FinishEstimateRepository
    ) {
        self.planRepository = planRepository
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.raceRepository = raceRepository
        self.finishTimeEstimator = finishTimeEstimator
        self.finishEstimateRepository = finishEstimateRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        do {
            plan = try await planRepository.getActivePlan()
        } catch {
            Logger.training.error("Dashboard failed to load plan: \(error)")
        }

        async let fitnessTask: () = loadFitness()
        async let estimateTask: () = loadFinishEstimate()
        async let lastRunTask: () = loadLastRun()
        async let racesTask: () = loadUpcomingRaces()
        _ = await (fitnessTask, estimateTask, lastRunTask, racesTask)

        isLoading = false
    }

    private func loadFitness() async {
        do {
            guard let athlete = try await athleteRepository.getAthlete() else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)
            runCount = runs.count
            guard !runs.isEmpty else {
                fitnessSnapshot = nil
                return
            }
            let snapshot = try await fitnessCalculator.execute(runs: runs, asOf: .now)
            try await fitnessRepository.saveSnapshot(snapshot)
            fitnessSnapshot = snapshot

            let from = Date.now.adding(days: -28)
            fitnessHistory = try await fitnessRepository.getSnapshots(from: from, to: .now)
        } catch {
            fitnessError = error.localizedDescription
            Logger.fitness.error("Failed to load fitness: \(error)")
        }
    }

    private func loadLastRun() async {
        do {
            let recent = try await runRepository.getRecentRuns(limit: 1)
            lastRun = recent.first
        } catch {
            Logger.training.debug("Dashboard: could not load last run: \(error)")
        }
    }

    private func loadUpcomingRaces() async {
        do {
            let allRaces = try await raceRepository.getRaces()
            let today = Date.now.startOfDay
            upcomingRaces = Array(
                allRaces
                    .filter { $0.date >= today }
                    .sorted { $0.date < $1.date }
                    .prefix(3)
            )
        } catch {
            Logger.training.debug("Dashboard: could not load races: \(error)")
        }
    }

    // MARK: - Fitness Computed

    var fitnessStatus: FitnessStatus {
        guard let snapshot = fitnessSnapshot else { return .noData }
        let acr = snapshot.acuteToChronicRatio
        if acr > 1.5 { return .injuryRisk }
        if acr < 0.8 && snapshot.fitness > 0 { return .detraining }
        return .optimal
    }

    var formDescription: String {
        guard let snapshot = fitnessSnapshot else { return "--" }
        if snapshot.form > 10 { return "Fresh" }
        if snapshot.form > -10 { return "Neutral" }
        return "Fatigued"
    }

    var recentFormHistory: [FitnessSnapshot] {
        let cutoff = Date.now.adding(days: -14)
        return fitnessHistory.filter { $0.date >= cutoff }
    }

    // MARK: - Plan Computed

    var currentWeek: TrainingWeek? {
        plan?.weeks.first { $0.containsToday }
    }

    var currentPhase: TrainingPhase? {
        currentWeek?.phase
    }

    var nextSession: TrainingSession? {
        guard let week = currentWeek else { return nil }
        let now = Date.now.startOfDay
        return week.sessions
            .filter { !$0.isCompleted && $0.date >= now && $0.type != .rest }
            .sorted { $0.date < $1.date }
            .first
    }

    var weeklyProgress: (completed: Int, total: Int) {
        guard let week = currentWeek else { return (0, 0) }
        let active = week.sessions.filter { $0.type != .rest }
        let done = active.filter(\.isCompleted).count
        return (done, active.count)
    }

    var weeklyDistanceKm: Double {
        guard let week = currentWeek else { return 0 }
        return week.sessions.filter(\.isCompleted).reduce(0) { $0 + $1.plannedDistanceKm }
    }

    var weeklyElevationM: Double {
        guard let week = currentWeek else { return 0 }
        return week.sessions.filter(\.isCompleted).reduce(0) { $0 + $1.plannedElevationGainM }
    }

    var weeklyTargetDistanceKm: Double {
        currentWeek?.targetVolumeKm ?? 0
    }

    var weeklyTargetElevationM: Double {
        currentWeek?.targetElevationGainM ?? 0
    }

    var weeksUntilRace: Int? {
        guard let plan else { return nil }
        let lastWeek = plan.weeks.last
        guard let raceEnd = lastWeek?.endDate else { return nil }
        return Date.now.weeksBetween(raceEnd)
    }

    // MARK: - Finish Estimate

    private func loadFinishEstimate() async {
        do {
            let races = try await raceRepository.getRaces()
            guard let race = races.first(where: { $0.priority == .aRace }) else { return }
            aRace = race

            if let cached = try await finishEstimateRepository.getEstimate(for: race.id) {
                finishEstimate = cached
            }

            guard let athlete = try await athleteRepository.getAthlete() else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)
            guard !runs.isEmpty else { return }

            var fitness: FitnessSnapshot?
            do {
                fitness = try await fitnessCalculator.execute(runs: runs, asOf: .now)
            } catch {
                Logger.fitness.warning("Could not calculate fitness for dashboard estimate: \(error)")
            }

            let estimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: race,
                recentRuns: runs,
                currentFitness: fitness
            )
            finishEstimate = estimate
            try await finishEstimateRepository.saveEstimate(estimate)
        } catch {
            Logger.training.debug("Dashboard finish estimate unavailable: \(error)")
        }
    }
}
