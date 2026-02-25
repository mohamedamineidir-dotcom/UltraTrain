import Foundation
import os

// MARK: - Fitness, Plan Computed, Calibration, AI Coach, Finish Estimate

extension DashboardViewModel {

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

    var adherencePercent: Double? {
        let progress = weeklyProgress
        guard progress.total > 0 else { return nil }
        return Double(progress.completed) / Double(progress.total)
    }

    var weeksUntilRace: Int? {
        guard let plan else { return nil }
        let lastWeek = plan.weeks.last
        guard let raceEnd = lastWeek?.endDate else { return nil }
        return Date.now.weeksBetween(raceEnd)
    }

    // MARK: - Calibration

    func buildCalibrations() async -> [RaceCalibration] {
        do {
            let allRaces = try await raceRepository.getRaces()
            var calibrations: [RaceCalibration] = []
            for race in allRaces where race.actualFinishTime != nil {
                guard let saved = try await finishEstimateRepository.getEstimate(for: race.id) else { continue }
                calibrations.append(RaceCalibration(
                    raceId: race.id,
                    predictedTime: saved.expectedTime,
                    actualTime: race.actualFinishTime!,
                    raceDistanceKm: race.distanceKm,
                    raceElevationGainM: race.elevationGainM
                ))
            }
            return calibrations
        } catch {
            return []
        }
    }

    // MARK: - AI Coach

    func loadAICoach() async {
        do {
            guard let athlete = try await athleteRepository.getAthlete() else { return }
            let runs = try await runRepository.getRuns(for: athlete.id)
            guard !runs.isEmpty else { return }

            // Fatigue detection
            let fatigueInput = FatiguePatternDetector.Input(
                recentRuns: runs,
                sleepHistory: sleepHistory,
                recoveryScores: recoveryScore.map { [$0] } ?? []
            )
            fatiguePatterns = FatiguePatternDetector.detect(input: fatigueInput)

            // Session optimizer
            if let phase = currentPhase {
                let optimizerInput = SessionOptimizer.Input(
                    plannedSession: nextSession,
                    currentPhase: phase,
                    readiness: readinessScore,
                    fatiguePatterns: fatiguePatterns,
                    weather: currentWeather,
                    availableTimeMinutes: nil
                )
                optimalSession = SessionOptimizer.optimize(input: optimizerInput)
            }

            // Performance trends
            let trendInput = PerformanceTrendAnalyzer.Input(
                recentRuns: runs,
                restingHeartRates: []
            )
            performanceTrends = PerformanceTrendAnalyzer.analyze(input: trendInput)
        } catch {
            Logger.aiCoach.debug("AI Coach loading failed: \(error)")
        }
    }

    // MARK: - Finish Estimate

    func loadFinishEstimate() async {
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

            let calibrations = await buildCalibrations()
            let estimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: race,
                recentRuns: runs,
                currentFitness: fitness,
                pastRaceCalibrations: calibrations
            )
            finishEstimate = estimate
            try await finishEstimateRepository.saveEstimate(estimate)
        } catch {
            Logger.training.debug("Dashboard finish estimate unavailable: \(error)")
        }
    }
}
