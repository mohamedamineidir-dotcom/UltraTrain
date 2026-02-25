import Foundation

extension PlanAdjustmentCalculator {

    // MARK: - Fatigue Load

    static func detectFatigueLoad(
        plan: TrainingPlan,
        now: Date,
        snapshot: FitnessSnapshot,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        let isFatigued = snapshot.form < -15 || snapshot.acuteToChronicRatio > 1.3
        guard isFatigued else { return }
        guard let cwi = currentWeekIndex else { return }

        let nowDay = Calendar.current.startOfDay(for: now)
        let affectedIds = plan.weeks[cwi].sessions
            .filter { Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
            .map(\.id)

        guard !affectedIds.isEmpty else { return }

        let isSevere = snapshot.form < -25 || snapshot.acuteToChronicRatio > 1.5
        let severity: AdjustmentSeverity = isSevere ? .urgent : .recommended
        let reductionPct = isSevere ? 25 : 15

        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .reduceFatigueLoad,
            severity: severity,
            title: "Reduce Training Load",
            message: "High fatigue detected (form: \(Int(snapshot.form)), ACR: \(String(format: "%.1f", snapshot.acuteToChronicRatio))). Reduce remaining sessions by \(reductionPct)%.",
            actionLabel: "Reduce \(reductionPct)%",
            affectedSessionIds: affectedIds
        ))
    }

    // MARK: - Swap to Recovery

    static func detectSwapToRecovery(
        plan: TrainingPlan,
        now: Date,
        snapshot: FitnessSnapshot,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        guard snapshot.acuteToChronicRatio > 1.5 else { return }
        guard let cwi = currentWeekIndex else { return }

        let hardTypes: Set<SessionType> = [.tempo, .intervals, .verticalGain]
        let nowDay = Calendar.current.startOfDay(for: now)

        let nextHardSession = plan.weeks[cwi].sessions.first {
            Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped
                && hardTypes.contains($0.type)
        }

        guard let session = nextHardSession else { return }

        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .swapToRecovery,
            severity: .urgent,
            title: "Swap to Recovery Run",
            message: "ACR is \(String(format: "%.1f", snapshot.acuteToChronicRatio)) — injury risk is high. Swap your \(session.type.rawValue) to a recovery run.",
            actionLabel: "Swap to Recovery",
            affectedSessionIds: [session.id]
        ))
    }

    // MARK: - Low Recovery

    static func detectLowRecovery(
        plan: TrainingPlan,
        now: Date,
        recovery: RecoveryScore,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        guard recovery.overallScore < AppConfiguration.Recovery.lowRecoveryThreshold else { return }
        guard let cwi = currentWeekIndex else { return }

        let nowDay = Calendar.current.startOfDay(for: now)
        let hardTypes: Set<SessionType> = [.tempo, .intervals, .verticalGain]

        if recovery.overallScore < AppConfiguration.Recovery.criticalRecoveryThreshold {
            let nextHard = plan.weeks[cwi].sessions.first {
                Calendar.current.startOfDay(for: $0.date) >= nowDay
                    && !$0.isCompleted && !$0.isSkipped
                    && hardTypes.contains($0.type)
            }
            if let session = nextHard {
                recommendations.append(PlanAdjustmentRecommendation(
                    id: UUID(),
                    type: .swapToRecoveryLowRecovery,
                    severity: .urgent,
                    title: "Recovery Critical",
                    message: "Recovery score is \(recovery.overallScore)/100. Swap your \(session.type.rawValue) to a recovery run.",
                    actionLabel: "Swap to Recovery",
                    affectedSessionIds: [session.id]
                ))
                return
            }
        }

        let affectedIds = plan.weeks[cwi].sessions
            .filter { Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
            .map(\.id)

        guard !affectedIds.isEmpty else { return }

        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .reduceLoadLowRecovery,
            severity: .recommended,
            title: "Reduce Load — Low Recovery",
            message: "Recovery score is \(recovery.overallScore)/100. Consider reducing today's session intensity by 20%.",
            actionLabel: "Reduce Intensity",
            affectedSessionIds: affectedIds
        ))
    }

    // MARK: - Accumulated Missed Volume

    static func detectAccumulatedMissedVolume(
        plan: TrainingPlan,
        now: Date,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        guard let cwi = currentWeekIndex else { return }
        let (missedDist, _) = MissedSessionRedistributor.calculateAccumulatedMissedVolume(plan: plan, now: now)
        let threshold = AppConfiguration.Training.accumulatedMissedVolumeThresholdKm
        guard missedDist >= threshold else { return }

        let pct = Int(AppConfiguration.Training.accumulatedMissedVolumeReductionPercent)
        let nowDay = Calendar.current.startOfDay(for: now)
        let affectedIds = plan.weeks[cwi].sessions
            .filter { Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
            .map(\.id)

        guard !affectedIds.isEmpty else { return }

        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .reduceTargetDueToAccumulatedMissed,
            severity: .urgent,
            title: "Lower Plan Targets",
            message: "You've missed \(Int(missedDist)) km in the last 2 weeks. Reduce remaining targets by \(pct)% to avoid overreaching.",
            actionLabel: "Reduce \(pct)%",
            affectedSessionIds: affectedIds
        ))
    }
}
