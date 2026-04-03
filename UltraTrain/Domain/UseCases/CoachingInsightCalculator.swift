import Foundation

enum CoachingInsightCalculator {

    private static let maxInsights = 3

    static func generate(
        fitness: FitnessSnapshot?,
        plan: TrainingPlan?,
        weeklyVolumes: [WeeklyVolume],
        nextRace: Race?,
        adherencePercent: Double?,
        recoveryScore: RecoveryScore? = nil,
        hrvTrend: HRVAnalyzer.HRVTrend? = nil,
        readinessScore: ReadinessScore? = nil
    ) -> [CoachingInsight] {
        var insights: [CoachingInsight] = []

        let daysUntilRace = nextRace.map { daysUntil($0.date) }
        let currentWeek = plan?.weeks.first { $0.containsToday }
        let previousWeek = previousWeek(in: plan, before: currentWeek)

        // 1. Race week (highest priority)
        if let race = nextRace, let days = daysUntilRace, days >= 0, days <= 7 {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .raceWeek,
                category: .guidance,
                title: "Race Week",
                message: "\(race.name) is in \(days) day\(days == 1 ? "" : "s"). Keep the volume low, legs fresh. You've done the work.",
                icon: "flag.checkered"
            ))
        }

        // 2. Ready to race
        if let race = nextRace, let days = daysUntilRace, days > 7, days <= 14,
           let form = fitness?.form, form > 5 {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .readyToRace,
                category: .positive,
                title: "Race Ready",
                message: "You're in great shape for \(race.name). Your form is strong right now.",
                icon: "star.fill"
            ))
        }

        // 3. Taper guidance
        if let phase = currentWeek?.phase, phase == .taper,
           daysUntilRace.map({ $0 > 7 }) ?? true {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .taperGuidance,
                category: .guidance,
                title: "Taper Phase",
                message: "Cut the volume but keep some intensity. Feeling flat or restless is totally normal during taper.",
                icon: "arrow.down.right.circle"
            ))
        }

        // 4. Form peaking (no race within 14 days)
        if let form = fitness?.form, form > 15,
           daysUntilRace.map({ $0 > 14 }) ?? true {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .formPeaking,
                category: .positive,
                title: "Form is Peaking",
                message: "Your fitness-to-fatigue balance is excellent right now. Great day for a quality session.",
                icon: "bolt.fill"
            ))
        }

        // 5. Recovery needed
        if let form = fitness?.form, form < -15 {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .recoveryNeeded,
                category: .warning,
                title: "Recovery Needed",
                message: "Fatigue is piling up. Prioritize sleep, good food, and easy sessions this week.",
                icon: "bed.double.fill"
            ))
        }

        // 6. Detraining risk
        if let snapshot = fitness, snapshot.acuteToChronicRatio < 0.8, snapshot.fitness > 10 {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .detrainingRisk,
                category: .warning,
                title: "Detraining Risk",
                message: "Training load has been dropping. Stay consistent to protect what you've built.",
                icon: "arrow.down.circle"
            ))
        }

        // 7. Phase transition
        if let current = currentWeek, let previous = previousWeek,
           current.phase != previous.phase {
            let phaseMessage = phaseGuidance(current.phase)
            insights.append(CoachingInsight(
                id: UUID(),
                type: .phaseTransition,
                category: .guidance,
                title: "Entering \(current.phase.rawValue.capitalized) Phase",
                message: phaseMessage,
                icon: "arrow.right.circle"
            ))
        }

        // 8. Consistent training
        if let adherence = adherencePercent, adherence >= 0.9 {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .consistentTraining,
                category: .positive,
                title: "Great Consistency",
                message: "You're nailing the plan this week. Keep it up.",
                icon: "checkmark.seal.fill"
            ))
        }

        // 9. Volume on track
        if let week = currentWeek, week.targetVolumeKm > 0 {
            let completed = week.sessions.filter(\.isCompleted).reduce(0.0) { $0 + $1.plannedDistanceKm }
            if completed >= week.targetVolumeKm * 0.8 {
                insights.append(CoachingInsight(
                    id: UUID(),
                    type: .volumeOnTrack,
                    category: .positive,
                    title: "Volume on Track",
                    message: "Weekly distance is right where it needs to be. Solid work.",
                    icon: "chart.bar.fill"
                ))
            }
        }

        // 10. Long run reminder
        if let week = currentWeek {
            let dayOfWeek = Calendar.current.component(.weekday, from: Date.now)
            let longRun = week.sessions.first { $0.type == .longRun && !$0.isCompleted && !$0.isSkipped }
            if longRun != nil, dayOfWeek >= 4 {
                insights.append(CoachingInsight(
                    id: UUID(),
                    type: .longRunReminder,
                    category: .guidance,
                    title: "Long Run Ahead",
                    message: "Your long run is still coming this week. Plan your route and nutrition in advance.",
                    icon: "figure.run"
                ))
            }
        }

        // 11. Sleep / Recovery
        if let recovery = recoveryScore {
            if recovery.overallScore < AppConfiguration.Recovery.lowRecoveryThreshold {
                insights.append(CoachingInsight(
                    id: UUID(),
                    type: .poorSleepRecovery,
                    category: .warning,
                    title: "Low Recovery",
                    message: "Recovery score is \(recovery.overallScore)/100. \(recovery.recommendation)",
                    icon: "moon.zzz.fill"
                ))
            } else if recovery.sleepQualityScore < AppConfiguration.Recovery.lowRecoveryThreshold
                        && recovery.overallScore >= AppConfiguration.Recovery.lowRecoveryThreshold {
                insights.append(CoachingInsight(
                    id: UUID(),
                    type: .sleepDeficit,
                    category: .warning,
                    title: "Sleep Deficit",
                    message: "Sleep quality has been low. Try getting to bed earlier tonight.",
                    icon: "bed.double.fill"
                ))
            } else if recovery.overallScore >= 80 {
                insights.append(CoachingInsight(
                    id: UUID(),
                    type: .goodRecovery,
                    category: .positive,
                    title: "Well Recovered",
                    message: "Recovery score is \(recovery.overallScore)/100. Good day for a quality session.",
                    icon: "battery.100.bolt"
                ))
            }
        }

        // 12. HRV declining
        if let trend = hrvTrend, trend.trend == .declining, trend.isSignificantChange {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .hrvDeclining,
                category: .warning,
                title: "HRV Declining",
                message: "Your heart rate variability has dropped. Consider going easier this week.",
                icon: "heart.text.square"
            ))
        }

        // 13. HRV improving
        if let trend = hrvTrend, trend.trend == .improving, trend.isSignificantChange {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .hrvImproving,
                category: .positive,
                title: "HRV Improving",
                message: "HRV is trending up. Your body is responding well to the training.",
                icon: "heart.text.square"
            ))
        }

        // 14. Ready for quality session
        if let readiness = readinessScore,
           readiness.status == .primed || readiness.status == .ready {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .readyForQualitySession,
                category: .positive,
                title: "Ready for Quality Work",
                message: "Readiness is high. \(readiness.sessionRecommendation.displayText).",
                icon: "bolt.heart.fill"
            ))
        }

        // 15. Session too intense for readiness
        if let readiness = readinessScore,
           (readiness.status == .fatigued || readiness.status == .needsRest) {
            insights.append(CoachingInsight(
                id: UUID(),
                type: .sessionTooIntenseForReadiness,
                category: .warning,
                title: "Low Readiness",
                message: "\(readiness.sessionRecommendation.displayText). Your body needs more recovery.",
                icon: "exclamationmark.triangle"
            ))
        }

        return Array(insights.prefix(maxInsights))
    }

    // MARK: - Helpers

    private static func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date.now.startOfDay, to: date.startOfDay).day ?? 0
    }

    private static func previousWeek(in plan: TrainingPlan?, before currentWeek: TrainingWeek?) -> TrainingWeek? {
        guard let plan, let current = currentWeek,
              let idx = plan.weeks.firstIndex(where: { $0.id == current.id }),
              idx > 0 else {
            return nil
        }
        return plan.weeks[idx - 1]
    }

    private static func phaseGuidance(_ phase: TrainingPhase) -> String {
        switch phase {
        case .base:
            "Building your aerobic foundation. Keep most runs easy and gradually increase volume."
        case .build:
            "Time to add race-specific work. Tempo, climbing, and longer efforts alongside your long runs."
        case .peak:
            "Quality over quantity now. Your hardest sessions happen here, but total volume levels off."
        case .taper:
            "Cutting volume but keeping some intensity. Your body is absorbing everything you've built."
        case .recovery:
            "Easy effort only. Let your body fully recover before the next block."
        case .race:
            "Race week. Stay loose, eat well, hydrate, and trust your preparation."
        }
    }
}
