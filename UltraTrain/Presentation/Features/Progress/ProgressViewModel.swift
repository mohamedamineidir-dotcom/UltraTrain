import Foundation
import SwiftUI
import os

@Observable
@MainActor
final class ProgressViewModel {

    // MARK: - Dependencies

    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository
    private let raceRepository: any RaceRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let fitnessRepository: any FitnessRepository

    // MARK: - State

    var weeklyVolumes: [WeeklyVolume] = []
    var weeklyAdherence: [WeeklyAdherence] = []
    var planAdherence: (completed: Int, total: Int) = (0, 0)
    var totalRuns = 0
    var fitnessSnapshots: [FitnessSnapshot] = []
    var currentFitnessSnapshot: FitnessSnapshot?
    var runTrendPoints: [RunTrendPoint] = []
    var personalRecords: [PersonalRecord] = []
    var phaseBlocks: [PhaseBlock] = []
    var injuryRiskAlerts: [InjuryRiskAlert] = []
    var raceReadiness: RaceReadinessForecast?
    var sessionTypeStats: [SessionTypeStats] = []
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository,
        raceRepository: any RaceRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        fitnessRepository: any FitnessRepository
    ) {
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.fitnessCalculator = fitnessCalculator
        self.fitnessRepository = fitnessRepository
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
            weeklyVolumes = WeeklyVolumeCalculator.compute(from: runs)
            runTrendPoints = computeRunTrends(from: runs)
            personalRecords = computePersonalRecords(from: runs)

            let plan = try await planRepository.getActivePlan()
            if let plan {
                planAdherence = computeAdherence(plan: plan)
                weeklyAdherence = computeWeeklyAdherence(plan: plan)
                phaseBlocks = PhaseVisualizationCalculator.computePhaseBlocks(from: plan)
                sessionTypeStats = SessionTypeBreakdownCalculator.compute(from: plan)
            }

            if !runs.isEmpty {
                let snapshot = try await fitnessCalculator.execute(runs: runs, asOf: .now)
                try await fitnessRepository.saveSnapshot(snapshot)
                currentFitnessSnapshot = snapshot
                let from = Date.now.adding(days: -28)
                fitnessSnapshots = try await fitnessRepository.getSnapshots(from: from, to: .now)

                injuryRiskAlerts = InjuryRiskCalculator.assess(
                    weeklyVolumes: weeklyVolumes,
                    currentACR: snapshot.acuteToChronicRatio,
                    monotony: snapshot.monotony
                )

                if let plan {
                    let races = try await raceRepository.getRaces()
                    if let aRace = races.first(where: { $0.priority == .aRace && $0.date > Date.now }) {
                        raceReadiness = RaceReadinessCalculator.forecast(
                            currentFitness: snapshot.fitness,
                            currentFatigue: snapshot.fatigue,
                            plannedWeeks: plan.weeks,
                            race: aRace
                        )
                    }
                }
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

    var formStatus: FormStatus {
        guard let snapshot = currentFitnessSnapshot else { return .noData }
        if snapshot.form > 15 { return .raceReady }
        if snapshot.form > 0 { return .fresh }
        if snapshot.form > -15 { return .building }
        return .fatigued
    }

    var formLabel: String {
        switch formStatus {
        case .raceReady: "Race Ready"
        case .fresh: "Fresh"
        case .building: "Building"
        case .fatigued: "Fatigued"
        case .noData: "--"
        }
    }

    var formIcon: String {
        switch formStatus {
        case .raceReady: "checkmark.seal.fill"
        case .fresh: "arrow.up.circle.fill"
        case .building: "minus.circle.fill"
        case .fatigued: "arrow.down.circle.fill"
        case .noData: "minus.circle"
        }
    }

    var formColor: Color {
        switch formStatus {
        case .raceReady, .fresh: Theme.Colors.success
        case .building: Theme.Colors.warning
        case .fatigued: Theme.Colors.danger
        case .noData: Theme.Colors.secondaryLabel
        }
    }

    var currentPhase: TrainingPhase? {
        phaseBlocks.first(where: \.isCurrentPhase)?.phase
    }

    // MARK: - Private

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

    func computeRunTrends(from runs: [CompletedRun]) -> [RunTrendPoint] {
        let sorted = runs.sorted { $0.date < $1.date }
        return sorted.enumerated().map { index, run in
            let windowStart = max(0, index - 4)
            let window = Array(sorted[windowStart...index])
            let avgPace = window.reduce(0.0) { $0 + $1.averagePaceSecondsPerKm } / Double(window.count)
            let hrWindow = window.compactMap(\.averageHeartRate)
            let avgHR: Double? = hrWindow.isEmpty ? nil : Double(hrWindow.reduce(0, +)) / Double(hrWindow.count)

            return RunTrendPoint(
                id: run.id,
                date: run.date,
                distanceKm: run.distanceKm,
                elevationGainM: run.elevationGainM,
                duration: run.duration,
                averagePaceSecondsPerKm: run.averagePaceSecondsPerKm,
                averageHeartRate: run.averageHeartRate,
                rollingAveragePace: window.count >= 2 ? avgPace : nil,
                rollingAverageHR: (hrWindow.count >= 2) ? avgHR : nil
            )
        }
    }

    func computePersonalRecords(from runs: [CompletedRun]) -> [PersonalRecord] {
        guard !runs.isEmpty else { return [] }
        var records: [PersonalRecord] = []

        if let longest = runs.max(by: { $0.distanceKm < $1.distanceKm }) {
            records.append(PersonalRecord(
                id: UUID(), type: .longestDistance,
                value: longest.distanceKm, date: longest.date, runId: longest.id
            ))
        }
        if let mostElev = runs.max(by: { $0.elevationGainM < $1.elevationGainM }) {
            records.append(PersonalRecord(
                id: UUID(), type: .mostElevation,
                value: mostElev.elevationGainM, date: mostElev.date, runId: mostElev.id
            ))
        }
        let runsWithPace = runs.filter { $0.averagePaceSecondsPerKm > 0 }
        if let fastest = runsWithPace.min(by: { $0.averagePaceSecondsPerKm < $1.averagePaceSecondsPerKm }) {
            records.append(PersonalRecord(
                id: UUID(), type: .fastestPace,
                value: fastest.averagePaceSecondsPerKm, date: fastest.date, runId: fastest.id
            ))
        }
        if let longestDur = runs.max(by: { $0.duration < $1.duration }) {
            records.append(PersonalRecord(
                id: UUID(), type: .longestDuration,
                value: longestDur.duration, date: longestDur.date, runId: longestDur.id
            ))
        }
        return records
    }
}
