import Foundation
import os

// MARK: - Plan Adjustments

extension TrainingPlanViewModel {

    var visibleRecommendations: [PlanAdjustmentRecommendation] {
        adjustmentRecommendations.filter { !dismissedRecommendationIds.contains($0.id) }
    }

    func checkForAdjustments() {
        guard let plan else {
            adjustmentRecommendations = []
            return
        }
        adjustmentRecommendations = PlanAdjustmentCalculator.analyze(plan: plan)
        let currentIds = Set(adjustmentRecommendations.map(\.id))
        dismissedRecommendationIds = dismissedRecommendationIds.intersection(currentIds)

        Task {
            guard let snapshot = try? await fitnessRepository.getLatestSnapshot() else { return }
            adjustmentRecommendations = PlanAdjustmentCalculator.analyze(
                plan: plan, fitnessSnapshot: snapshot
            )
            let updatedIds = Set(adjustmentRecommendations.map(\.id))
            dismissedRecommendationIds = dismissedRecommendationIds.intersection(updatedIds)
        }
    }

    func dismissRecommendation(_ recommendation: PlanAdjustmentRecommendation) {
        dismissedRecommendationIds.insert(recommendation.id)
    }

    func applyRecommendation(_ recommendation: PlanAdjustmentRecommendation) async {
        guard var currentPlan = plan else { return }
        isApplyingAdjustment = true

        do {
            switch recommendation.type {
            case .rescheduleKeySession:
                try await applyReschedule(recommendation, plan: &currentPlan)
            case .reduceVolumeAfterLowAdherence:
                let factor = 1.0 - AppConfiguration.Training.lowAdherenceVolumeReductionPercent / 100.0
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
            case .convertToRecoveryWeek:
                let factor = 1.0 - AppConfiguration.Training.recoveryWeekVolumeReductionPercent / 100.0
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
                if let cwi = currentPlan.currentWeekIndex {
                    currentPlan.weeks[cwi].isRecoveryWeek = true
                    try await planRepository.updatePlan(currentPlan)
                }
            case .bulkMarkMissedAsSkipped:
                try await applyBulkSkip(recommendation, plan: &currentPlan)
            case .reduceFatigueLoad:
                let isSevere = recommendation.severity == .urgent
                let factor = isSevere ? 0.75 : 0.85
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
            case .swapToRecovery:
                try await applySwapToRecovery(recommendation, plan: &currentPlan)
            case .reduceLoadLowRecovery:
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: 0.80)
            case .swapToRecoveryLowRecovery:
                try await applySwapToRecovery(recommendation, plan: &currentPlan)
            case .redistributeMissedVolume:
                try await applyVolumeRedistribution(recommendation, plan: &currentPlan)
            case .convertEasyToQuality:
                try await applyConvertToQuality(recommendation, plan: &currentPlan)
            case .reduceTargetDueToAccumulatedMissed:
                let factor = 1.0 - AppConfiguration.Training.accumulatedMissedVolumeReductionPercent / 100.0
                try await applyVolumeReduction(recommendation, plan: &currentPlan, factor: factor)
            }

            plan = currentPlan
            checkForAdjustments()
            await updateWidgets()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to apply adjustment: \(error)")
        }

        isApplyingAdjustment = false
    }

    // MARK: - Apply Helpers

    func applyReschedule(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        guard rec.affectedSessionIds.count == 2 else { return }
        let missedId = rec.affectedSessionIds[0]
        let restSlotId = rec.affectedSessionIds[1]

        guard let (mwi, msi) = findSession(id: missedId, in: plan),
              let (rwi, rsi) = findSession(id: restSlotId, in: plan) else { return }

        let newDate = plan.weeks[rwi].sessions[rsi].date
        plan.weeks[mwi].sessions[msi].date = newDate

        plan.weeks[mwi].sessions.sort { $0.date < $1.date }
        if mwi != rwi {
            plan.weeks[rwi].sessions.sort { $0.date < $1.date }
        }

        // Find the updated index after sort
        if let updatedIdx = plan.weeks[mwi].sessions.firstIndex(where: { $0.id == missedId }) {
            try await planRepository.updateSession(plan.weeks[mwi].sessions[updatedIdx])
        }
    }

    func applyVolumeReduction(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan,
        factor: Double
    ) async throws {
        let affectedIds = Set(rec.affectedSessionIds)

        for wi in plan.weeks.indices {
            for si in plan.weeks[wi].sessions.indices {
                let session = plan.weeks[wi].sessions[si]
                guard affectedIds.contains(session.id) else { continue }

                plan.weeks[wi].sessions[si].plannedDistanceKm *= factor
                plan.weeks[wi].sessions[si].plannedElevationGainM *= factor
                plan.weeks[wi].sessions[si].plannedDuration *= factor
                try await planRepository.updateSession(plan.weeks[wi].sessions[si])
            }
        }
    }

    func applyBulkSkip(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        let affectedIds = Set(rec.affectedSessionIds)

        for wi in plan.weeks.indices {
            for si in plan.weeks[wi].sessions.indices {
                guard affectedIds.contains(plan.weeks[wi].sessions[si].id) else { continue }
                plan.weeks[wi].sessions[si].isSkipped = true
                try await planRepository.updateSession(plan.weeks[wi].sessions[si])
            }
        }
    }

    func applySwapToRecovery(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        guard let sessionId = rec.affectedSessionIds.first,
              let (wi, si) = findSession(id: sessionId, in: plan) else { return }

        plan.weeks[wi].sessions[si].type = .recovery
        plan.weeks[wi].sessions[si].intensity = .easy
        plan.weeks[wi].sessions[si].plannedDistanceKm *= 0.5
        plan.weeks[wi].sessions[si].plannedElevationGainM = 0
        plan.weeks[wi].sessions[si].plannedDuration *= 0.5
        plan.weeks[wi].sessions[si].description = "Recovery run (auto-adjusted due to high fatigue)"
        try await planRepository.updateSession(plan.weeks[wi].sessions[si])
    }

    func applyVolumeRedistribution(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        for adjustment in rec.volumeAdjustments {
            guard let (wi, si) = findSession(id: adjustment.sessionId, in: plan) else { continue }
            plan.weeks[wi].sessions[si].plannedDistanceKm += adjustment.addedDistanceKm
            plan.weeks[wi].sessions[si].plannedElevationGainM += adjustment.addedElevationGainM
            try await planRepository.updateSession(plan.weeks[wi].sessions[si])
        }
        // Mark the missed session as skipped
        if let missedId = rec.affectedSessionIds.first,
           let (wi, si) = findSession(id: missedId, in: plan) {
            plan.weeks[wi].sessions[si].isSkipped = true
            try await planRepository.updateSession(plan.weeks[wi].sessions[si])
        }
    }

    func applyConvertToQuality(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        for adjustment in rec.volumeAdjustments {
            guard let newType = adjustment.newType,
                  let (wi, si) = findSession(id: adjustment.sessionId, in: plan) else { continue }
            plan.weeks[wi].sessions[si].type = newType
            plan.weeks[wi].sessions[si].description = "\(newType.rawValue.capitalized) (converted from recovery)"
            try await planRepository.updateSession(plan.weeks[wi].sessions[si])
        }
        // Mark the missed session as skipped
        if let missedId = rec.affectedSessionIds.first,
           let (wi, si) = findSession(id: missedId, in: plan) {
            plan.weeks[wi].sessions[si].isSkipped = true
            try await planRepository.updateSession(plan.weeks[wi].sessions[si])
        }
    }

    func findSession(id: UUID, in plan: TrainingPlan) -> (weekIndex: Int, sessionIndex: Int)? {
        for (wi, week) in plan.weeks.enumerated() {
            for (si, session) in week.sessions.enumerated() {
                if session.id == id { return (wi, si) }
            }
        }
        return nil
    }
}
