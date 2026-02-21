import Foundation

enum PlanAdjustmentCalculator {

    static func analyze(
        plan: TrainingPlan,
        now: Date = .now,
        fitnessSnapshot: FitnessSnapshot? = nil,
        recoveryScore: RecoveryScore? = nil
    ) -> [PlanAdjustmentRecommendation] {
        var recommendations: [PlanAdjustmentRecommendation] = []

        let currentWeekIndex = findCurrentWeekIndex(plan: plan, now: now)
        let hasRecoveryConversion = detectExtendedGap(
            plan: plan, now: now, currentWeekIndex: currentWeekIndex, into: &recommendations
        )

        if !hasRecoveryConversion {
            detectMissedKeySessionsToReschedule(
                plan: plan, now: now, currentWeekIndex: currentWeekIndex, into: &recommendations
            )
            detectLowAdherenceWeeks(
                plan: plan, now: now, currentWeekIndex: currentWeekIndex, into: &recommendations
            )
        }

        detectStaleMissedSessions(plan: plan, now: now, into: &recommendations)

        let redistribution = MissedSessionRedistributor.analyzeRedistribution(
            plan: plan, now: now, currentWeekIndex: currentWeekIndex
        )
        recommendations.append(contentsOf: redistribution.recommendations)

        detectAccumulatedMissedVolume(plan: plan, now: now, currentWeekIndex: currentWeekIndex, into: &recommendations)

        if let snapshot = fitnessSnapshot {
            detectFatigueLoad(
                plan: plan, now: now, snapshot: snapshot,
                currentWeekIndex: currentWeekIndex, into: &recommendations
            )
            detectSwapToRecovery(
                plan: plan, now: now, snapshot: snapshot,
                currentWeekIndex: currentWeekIndex, into: &recommendations
            )
        }

        if let recovery = recoveryScore {
            detectLowRecovery(
                plan: plan, now: now, recovery: recovery,
                currentWeekIndex: currentWeekIndex, into: &recommendations
            )
        }

        return recommendations.sorted { $0.severity > $1.severity }
    }

    // MARK: - Current Week

    private static func findCurrentWeekIndex(plan: TrainingPlan, now: Date) -> Int? {
        plan.weeks.firstIndex { now >= $0.startDate && now <= $0.endDate }
    }

    // MARK: - Missed Key Sessions

    private static func detectMissedKeySessionsToReschedule(
        plan: TrainingPlan,
        now: Date,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        let keyTypes: Set<SessionType> = [.longRun, .intervals, .tempo, .verticalGain]
        let nowDay = Calendar.current.startOfDay(for: now)

        // Collect missed key sessions from current and previous week
        var missedSessions: [(weekIndex: Int, sessionIndex: Int, session: TrainingSession)] = []
        let weeksToCheck: [Int]
        if let cwi = currentWeekIndex {
            weeksToCheck = cwi > 0 ? [cwi - 1, cwi] : [cwi]
        } else {
            return
        }

        for wi in weeksToCheck {
            for (si, session) in plan.weeks[wi].sessions.enumerated() {
                let sessionDay = Calendar.current.startOfDay(for: session.date)
                if sessionDay < nowDay
                    && !session.isCompleted
                    && !session.isSkipped
                    && keyTypes.contains(session.type) {
                    missedSessions.append((wi, si, session))
                }
            }
        }

        guard !missedSessions.isEmpty else { return }

        // Find available rest slots in current and next week
        let restSlotWeeks: [Int]
        if let cwi = currentWeekIndex {
            restSlotWeeks = cwi + 1 < plan.weeks.count ? [cwi, cwi + 1] : [cwi]
        } else {
            return
        }

        var availableRestSlots: [(weekIndex: Int, sessionIndex: Int, session: TrainingSession)] = []
        for wi in restSlotWeeks {
            for (si, session) in plan.weeks[wi].sessions.enumerated() {
                let sessionDay = Calendar.current.startOfDay(for: session.date)
                if sessionDay >= nowDay
                    && session.type == .rest
                    && !session.isCompleted {
                    availableRestSlots.append((wi, si, session))
                }
            }
        }

        // Match each missed key session to the earliest available rest slot
        var usedSlotIds: Set<UUID> = []
        for missed in missedSessions {
            guard let slot = availableRestSlots.first(where: { !usedSlotIds.contains($0.session.id) }) else {
                break
            }
            usedSlotIds.insert(slot.session.id)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            let targetDay = dateFormatter.string(from: slot.session.date)

            recommendations.append(PlanAdjustmentRecommendation(
                id: UUID(),
                type: .rescheduleKeySession,
                severity: .recommended,
                title: "Reschedule \(missed.session.type.rawValue.capitalized)",
                message: "You missed your \(missed.session.type.rawValue) session. Move it to \(targetDay)?",
                actionLabel: "Reschedule",
                affectedSessionIds: [missed.session.id, slot.session.id]
            ))
        }
    }

    // MARK: - Low Adherence

    private static func detectLowAdherenceWeeks(
        plan: TrainingPlan,
        now: Date,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        guard let cwi = currentWeekIndex, cwi > 0 else { return }

        let previousWeek = plan.weeks[cwi - 1]
        let nowDay = Calendar.current.startOfDay(for: now)

        // Only evaluate fully completed weeks
        let allPast = previousWeek.sessions.allSatisfy {
            Calendar.current.startOfDay(for: $0.date) < nowDay
        }
        guard allPast else { return }

        let activeSessions = previousWeek.sessions.filter { $0.type != .rest }
        guard !activeSessions.isEmpty else { return }

        let completed = activeSessions.filter(\.isCompleted).count
        let adherence = Double(completed) / Double(activeSessions.count)

        guard adherence < AppConfiguration.Training.lowAdherenceThreshold else { return }

        // Target: future non-completed non-rest sessions in current week
        let currentWeek = plan.weeks[cwi]
        let affectedIds = currentWeek.sessions
            .filter { Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
            .map(\.id)

        guard !affectedIds.isEmpty else { return }

        let pct = Int(AppConfiguration.Training.lowAdherenceVolumeReductionPercent)
        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .reduceVolumeAfterLowAdherence,
            severity: .recommended,
            title: "Reduce This Week's Volume",
            message: "Last week's adherence was \(Int(adherence * 100))%. Reduce remaining sessions by \(pct)% to ease back in.",
            actionLabel: "Reduce Volume",
            affectedSessionIds: affectedIds
        ))
    }

    // MARK: - Extended Gap

    @discardableResult
    private static func detectExtendedGap(
        plan: TrainingPlan,
        now: Date,
        currentWeekIndex: Int?,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) -> Bool {
        guard let cwi = currentWeekIndex else { return false }
        let currentWeek = plan.weeks[cwi]

        // Don't suggest if already a recovery week
        guard !currentWeek.isRecoveryWeek else { return false }

        let allSessions = plan.weeks.flatMap(\.sessions)
        let completedDates = allSessions
            .filter(\.isCompleted)
            .map(\.date)

        let gapDays = AppConfiguration.Training.extendedGapDays
        let needsRecovery: Bool

        if let mostRecent = completedDates.max() {
            let daysSince = Calendar.current.dateComponents([.day], from: mostRecent, to: now).day ?? 0
            needsRecovery = daysSince >= gapDays
        } else {
            // No completed sessions at all — check if plan has been active long enough
            let planStartDate = plan.weeks.first?.startDate ?? now
            let daysSinceStart = Calendar.current.dateComponents([.day], from: planStartDate, to: now).day ?? 0
            needsRecovery = daysSinceStart >= gapDays
        }

        guard needsRecovery else { return false }

        let nowDay = Calendar.current.startOfDay(for: now)
        let affectedIds = currentWeek.sessions
            .filter { Calendar.current.startOfDay(for: $0.date) >= nowDay
                && !$0.isCompleted && !$0.isSkipped && $0.type != .rest }
            .map(\.id)

        guard !affectedIds.isEmpty else { return false }

        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .convertToRecoveryWeek,
            severity: .urgent,
            title: "Convert to Recovery Week",
            message: "No training logged in \(gapDays)+ days. Ease back with a lighter recovery week.",
            actionLabel: "Convert to Recovery",
            affectedSessionIds: affectedIds
        ))

        return true
    }

    // MARK: - Stale Missed Sessions

    private static func detectStaleMissedSessions(
        plan: TrainingPlan,
        now: Date,
        into recommendations: inout [PlanAdjustmentRecommendation]
    ) {
        let nowDay = Calendar.current.startOfDay(for: now)

        let missedSessions = plan.weeks.flatMap(\.sessions).filter {
            Calendar.current.startOfDay(for: $0.date) < nowDay
                && !$0.isCompleted
                && !$0.isSkipped
                && $0.type != .rest
        }

        let threshold = AppConfiguration.Training.staleMissedSessionThreshold
        guard missedSessions.count >= threshold else { return }

        recommendations.append(PlanAdjustmentRecommendation(
            id: UUID(),
            type: .bulkMarkMissedAsSkipped,
            severity: .suggestion,
            title: "Clean Up Missed Sessions",
            message: "\(missedSessions.count) past sessions are unmarked. Mark them as skipped to keep your plan tidy.",
            actionLabel: "Skip All Missed",
            affectedSessionIds: missedSessions.map(\.id)
        ))
    }

    // MARK: - Fatigue Load

    private static func detectFatigueLoad(
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

    private static func detectSwapToRecovery(
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

    private static func detectLowRecovery(
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

    private static func detectAccumulatedMissedVolume(
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
