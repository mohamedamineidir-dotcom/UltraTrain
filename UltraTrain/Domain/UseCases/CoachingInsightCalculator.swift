import Foundation

enum CoachingInsightCalculator {

    private static let maxInsights = 3

    static func generate(
        fitness: FitnessSnapshot?,
        plan: TrainingPlan?,
        weeklyVolumes: [WeeklyVolume],
        nextRace: Race?,
        adherencePercent: Double?
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
                message: "\(race.name) is in \(days) day\(days == 1 ? "" : "s"). Reduce volume, keep legs fresh. Trust your training.",
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
                message: "You're in great shape for \(race.name). Form is strong — confidence is high.",
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
                message: "Reduce volume 30-40% but maintain some intensity. Feeling flat is normal — your body is absorbing the training.",
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
                message: "Your fitness-to-fatigue balance is excellent. Great time for a quality long run or tempo session.",
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
                message: "Fatigue is high. Prioritize sleep, nutrition, and easy sessions this week.",
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
                message: "Training load is dropping. Maintain consistency to protect your fitness gains.",
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
                message: "You're nailing the plan this week. Keep up the excellent work.",
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
                    message: "Weekly distance is hitting targets. Your preparation is solid.",
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
                    message: "Your long run is still ahead this week. Plan your route and nutrition in advance.",
                    icon: "figure.run"
                ))
            }
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
            "Focus on building your aerobic foundation. Keep most runs easy and gradually increase volume."
        case .build:
            "Time to add race-specific intensity. Include tempo and vertical gain sessions alongside your long runs."
        case .peak:
            "Quality over quantity now. Your hardest sessions happen here, but total volume starts to level off."
        case .taper:
            "Reduce volume 30-40% but maintain some intensity. Your body is absorbing the training."
        case .recovery:
            "Easy effort only. Let your body fully recover before the next training block."
        case .race:
            "Race week. Stay loose, eat well, hydrate, and trust your preparation."
        }
    }
}
