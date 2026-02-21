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
            runTrendPoints = computeRunTrends(from: runs)
            personalRecords = computePersonalRecords(from: runs)

            let plan = try await planRepository.getActivePlan()
            weeklyVolumes = WeeklyVolumeCalculator.compute(from: runs, plan: plan)
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

    // MARK: - This Week Summary

    var currentWeekVolume: WeeklyVolume? {
        weeklyVolumes.last
    }

    var previousWeekVolume: WeeklyVolume? {
        guard weeklyVolumes.count >= 2 else { return nil }
        return weeklyVolumes[weeklyVolumes.count - 2]
    }

    var currentWeekDistanceFormatted: String {
        guard let week = currentWeekVolume else { return "0" }
        return String(format: "%.1f", week.distanceKm)
    }

    var currentWeekElevationFormatted: String {
        guard let week = currentWeekVolume else { return "0" }
        return String(format: "%.0f", week.elevationGainM)
    }

    var currentWeekDurationFormatted: String {
        guard let duration = currentWeekVolume?.duration else { return "0h" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h\(String(format: "%02d", minutes))m" }
        return "\(minutes)m"
    }

    var distanceTrend: TrendDirection {
        computeTrend(current: currentWeekVolume?.distanceKm, previous: previousWeekVolume?.distanceKm)
    }

    var elevationTrend: TrendDirection {
        computeTrend(current: currentWeekVolume?.elevationGainM, previous: previousWeekVolume?.elevationGainM)
    }

    var durationTrend: TrendDirection {
        computeTrend(current: currentWeekVolume?.duration, previous: previousWeekVolume?.duration)
    }

    private func computeTrend(current: Double?, previous: Double?) -> TrendDirection {
        guard let current, let previous, previous > 0 else {
            return (current ?? 0) > 0 ? .up : .stable
        }
        if current > previous * 1.05 { return .up }
        if current < previous * 0.95 { return .down }
        return .stable
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
        PersonalRecordCalculator.computeAll(from: runs)
    }
}
