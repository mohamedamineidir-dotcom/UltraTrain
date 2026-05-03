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
            // Fetch fitness + recovery in parallel — both feed the
            // analyser. Recovery is optional (nil-safe inside analyse);
            // when present, it activates the swapToRecoveryLowRecovery
            // and reduceLoadLowRecovery recommendations that Commit E
            // added to the urgent auto-apply set. Result: poor overnight
            // HRV/sleep silently swaps today's hard session for an easy
            // run instead of just showing a banner the athlete has to
            // accept.
            let snapshot: FitnessSnapshot?
            do {
                snapshot = try await fitnessRepository.getLatestSnapshot()
            } catch {
                Logger.fitness.warning("TrainingPlanViewModel: failed to load fitness snapshot for adjustments: \(error)")
                return
            }
            let recoveryScore: RecoveryScore? = await loadLatestRecoveryScore()
            adjustmentRecommendations = PlanAdjustmentCalculator.analyze(
                plan: plan,
                fitnessSnapshot: snapshot,
                recoveryScore: recoveryScore
            )
            let updatedIds = Set(adjustmentRecommendations.map(\.id))
            dismissedRecommendationIds = dismissedRecommendationIds.intersection(updatedIds)
            await autoApplyUrgentAdjustments()
        }
    }

    /// Pulls the most-recent recovery snapshot from the optional
    /// `recoveryRepository`. Returns nil when the dependency wasn't
    /// injected (e.g. tests, contexts without HealthKit) — the analyser
    /// then falls back to the existing fitness-only adjustment path.
    private func loadLatestRecoveryScore() async -> RecoveryScore? {
        guard let repo = recoveryRepository else { return nil }
        do {
            let calendar = Calendar.current
            let now = Date.now
            // invariant: Calendar.date(byAdding:) always succeeds for simple offsets
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            let snapshots = try await repo.getSnapshots(from: weekAgo, to: now)
            return snapshots.last?.recoveryScore
        } catch {
            Logger.recovery.warning("TrainingPlanViewModel: failed to load recovery snapshot for adjustments: \(error)")
            return nil
        }
    }

    /// Auto-apply urgent-severity recommendations that the athlete
    /// shouldn't have to reason about — adherence-driven volume cuts and
    /// severe fatigue load reduction. A coach would just rebuild after 3
    /// missed key sessions; the athlete shouldn't have to read a banner
    /// and decide. Lower-severity versions of these recommendations stay
    /// as banners (athlete-facing decision).
    private func autoApplyUrgentAdjustments() async {
        // Auto-apply set covers both adherence/fatigue (Commit A original)
        // and same-day readiness signals: when overnight HRV/sleep
        // produced a `swapToRecoveryLowRecovery` or `reduceLoadLowRecovery`
        // recommendation at urgent severity, the session swap or volume
        // cut applies silently. The athlete sees today's session already
        // updated when they open the app — no banner-then-decide round
        // trip. Recovery-driven recommendations require the analyzer to
        // be passed a `RecoveryScore`; that wiring is incremental — once
        // a call site supplies it, this auto-apply path picks it up.
        let autoApplyTypes: Set<PlanAdjustmentType> = [
            .reduceTargetDueToAccumulatedMissed,
            .reduceFatigueLoad,
            .swapToRecoveryLowRecovery,
            .reduceLoadLowRecovery
        ]
        let candidates = adjustmentRecommendations.filter {
            $0.severity == .urgent
                && autoApplyTypes.contains($0.type)
                && !dismissedRecommendationIds.contains($0.id)
        }
        guard !candidates.isEmpty else { return }
        for rec in candidates {
            await applyRecommendation(rec)
            // Hide from banner — already applied silently.
            dismissedRecommendationIds.insert(rec.id)
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
            case .menstrualBleedDayOptions, .menstrualPrePeriodOptions:
                // Option-style recommendations: tapping the banner action
                // presents `MenstrualAdaptationOptionsSheet`, which calls
                // back into `applyMenstrualChoice(_:choice:)` once the
                // user picks defer / reduce / swap / keep. No plan
                // mutation here — the sheet drives it.
                presentedMenstrualOptions = recommendation
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

    // MARK: - Menstrual Adaptation Choice

    /// Dispatcher called by `MenstrualAdaptationOptionsSheet` after the
    /// athlete picks one of the option-style choices. Performs the
    /// concrete plan edit, dismisses the recommendation, and refreshes
    /// the adjustment list.
    ///
    /// `.keep` is intentionally a no-op on the plan — the user
    /// explicitly chose to keep the planned session as-is, which is
    /// always a first-class option per the menstrual MVP spec
    /// (McNulty 2020: many athletes train and PR through symptomatic
    /// days without issue).
    func applyMenstrualChoice(
        _ rec: PlanAdjustmentRecommendation,
        choice: MenstrualAdaptationOptionsSheet.Choice
    ) async {
        guard var currentPlan = plan else { return }
        isApplyingAdjustment = true
        do {
            switch choice {
            case .deferDays(let days):
                try await applyMenstrualDefer(rec, plan: &currentPlan, days: days)
            case .reduceVolume(let factor, let lowerToEasy):
                try await applyMenstrualReduce(
                    rec, plan: &currentPlan,
                    factor: factor, lowerToEasy: lowerToEasy
                )
            case .swapToEasy:
                try await applyMenstrualSwap(rec, plan: &currentPlan)
            case .keep:
                break // explicit user choice — leave plan untouched
            }
            plan = currentPlan
            dismissRecommendation(rec)
            checkForAdjustments()
            await updateWidgets()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to apply menstrual choice: \(error)")
        }
        isApplyingAdjustment = false
    }

    /// Pushes the affected session(s) forward by `days`. The menstrual
    /// calculator typically emits a single affected session (the next
    /// quality session in the symptom window) — but the implementation
    /// supports the multi-session case in case v2 widens it.
    private func applyMenstrualDefer(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan,
        days: Int
    ) async throws {
        let affectedIds = Set(rec.affectedSessionIds)
        var weeksToSort = Set<Int>()
        for wi in plan.weeks.indices {
            for si in plan.weeks[wi].sessions.indices {
                let id = plan.weeks[wi].sessions[si].id
                guard affectedIds.contains(id) else { continue }
                let oldDate = plan.weeks[wi].sessions[si].date
                if let newDate = Calendar.current.date(byAdding: .day, value: days, to: oldDate) {
                    plan.weeks[wi].sessions[si].date = newDate
                    weeksToSort.insert(wi)
                }
            }
        }
        for wi in weeksToSort {
            plan.weeks[wi].sessions.sort { $0.date < $1.date }
        }
        // Persist after sorting so each save sees the final ordered state
        for wi in plan.weeks.indices {
            for session in plan.weeks[wi].sessions where affectedIds.contains(session.id) {
                try await planRepository.updateSession(session)
            }
        }
    }

    /// Cuts planned distance/elevation/duration by `factor` (e.g. 0.75
    /// = 25% reduction). Optionally drops the session intensity to
    /// .easy — used for the bleed-day "reduce + easy effort" path
    /// where the athlete keeps the session structure but dials it back.
    private func applyMenstrualReduce(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan,
        factor: Double,
        lowerToEasy: Bool
    ) async throws {
        let affectedIds = Set(rec.affectedSessionIds)
        for wi in plan.weeks.indices {
            for si in plan.weeks[wi].sessions.indices {
                guard affectedIds.contains(plan.weeks[wi].sessions[si].id) else { continue }
                plan.weeks[wi].sessions[si].plannedDistanceKm *= factor
                plan.weeks[wi].sessions[si].plannedElevationGainM *= factor
                plan.weeks[wi].sessions[si].plannedDuration *= factor
                if lowerToEasy {
                    plan.weeks[wi].sessions[si].intensity = .easy
                }
                try await planRepository.updateSession(plan.weeks[wi].sessions[si])
            }
        }
    }

    /// Swaps the affected session to a recovery run. Different from
    /// `applySwapToRecovery` (which auto-overwrites the description
    /// with a fatigue-adjustment string and cuts to 50%) — menstrual
    /// swap keeps the original description and uses a 60% volume cut
    /// since it's a planned choice rather than an auto-applied
    /// fatigue protection.
    private func applyMenstrualSwap(
        _ rec: PlanAdjustmentRecommendation,
        plan: inout TrainingPlan
    ) async throws {
        guard let sessionId = rec.affectedSessionIds.first,
              let (wi, si) = findSession(id: sessionId, in: plan) else { return }
        plan.weeks[wi].sessions[si].type = .recovery
        plan.weeks[wi].sessions[si].intensity = .easy
        plan.weeks[wi].sessions[si].plannedDistanceKm *= 0.6
        plan.weeks[wi].sessions[si].plannedElevationGainM = 0
        plan.weeks[wi].sessions[si].plannedDuration *= 0.6
        try await planRepository.updateSession(plan.weeks[wi].sessions[si])
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
