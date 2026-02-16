import Foundation
import os

@Observable
@MainActor
final class TrainingLoadViewModel {

    // MARK: - Dependencies

    private let trainingLoadCalculator: any CalculateTrainingLoadUseCase
    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository
    private let planRepository: any TrainingPlanRepository

    // MARK: - State

    var summary: TrainingLoadSummary?
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(
        trainingLoadCalculator: any CalculateTrainingLoadUseCase,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository,
        planRepository: any TrainingPlanRepository
    ) {
        self.trainingLoadCalculator = trainingLoadCalculator
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
            let plan = try await planRepository.getActivePlan()
            summary = try await trainingLoadCalculator.execute(
                runs: runs,
                plan: plan,
                asOf: .now
            )
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load training load: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed

    var currentLoadFormatted: String {
        guard let load = summary?.currentWeekLoad.actualLoad else { return "0" }
        return String(format: "%.0f", load)
    }

    var currentDistanceFormatted: String {
        guard let km = summary?.currentWeekLoad.distanceKm else { return "0" }
        return String(format: "%.1f", km)
    }

    var currentDurationFormatted: String {
        guard let duration = summary?.currentWeekLoad.duration else { return "0h" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))m"
        }
        return "\(minutes)m"
    }

    var loadTrend: TrendDirection {
        guard let history = summary?.weeklyHistory, history.count >= 2 else { return .stable }
        let current = history[history.count - 1].actualLoad
        let previous = history[history.count - 2].actualLoad
        if current > previous * 1.05 { return .up }
        if current < previous * 0.95 { return .down }
        return .stable
    }

    var currentACR: Double {
        summary?.acrTrend.last?.value ?? 0
    }

    var acrStatusIcon: String {
        if currentACR > 1.5 { return "exclamationmark.triangle.fill" }
        if currentACR < 0.8 { return "arrow.down.circle.fill" }
        return "checkmark.circle.fill"
    }

    var acrStatusLabel: String {
        if currentACR > 1.5 { return "Injury Risk" }
        if currentACR < 0.8 { return "Detraining Risk" }
        return "Optimal"
    }

    var monotonyDescription: String {
        guard let level = summary?.monotonyLevel else { return "" }
        switch level {
        case .low:
            return "Your training has good variety across the week."
        case .normal:
            return "Training variety is acceptable."
        case .high:
            return "Training is too repetitive. Vary your session types and intensities."
        }
    }
}
