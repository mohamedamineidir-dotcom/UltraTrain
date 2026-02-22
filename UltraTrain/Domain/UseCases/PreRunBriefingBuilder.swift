import Foundation

enum PreRunBriefingBuilder {

    static func build(
        session: TrainingSession?,
        readinessScore: ReadinessScore?,
        recoveryScore: RecoveryScore?,
        weather: WeatherSnapshot?,
        fatiguePatterns: [FatiguePattern],
        recentRuns: [CompletedRun],
        athlete: Athlete?
    ) -> PreRunBriefing {
        let adjustment: AdaptiveSessionAdjustment?
        if let session {
            adjustment = AdaptiveSessionAdjuster.adjust(
                session: session,
                readiness: readinessScore,
                recoveryScore: recoveryScore,
                fatiguePatterns: fatiguePatterns,
                weather: weather
            )
        } else {
            adjustment = nil
        }

        let readinessStatus: RecoveryStatus?
        if let readinessScore {
            readinessStatus = mapReadinessToRecoveryStatus(readinessScore.status)
        } else if let recoveryScore {
            readinessStatus = recoveryScore.status
        } else {
            readinessStatus = nil
        }

        let pacingRec = buildPacingRecommendation(
            session: session,
            readinessScore: readinessScore
        )
        let nutritionRec = buildNutritionReminder(session: session, athlete: athlete)
        let focusPoint = buildFocusPoint(
            session: session,
            readinessScore: readinessScore,
            adjustment: adjustment
        )
        let performanceSummary = buildPerformanceSummary(recentRuns: recentRuns)

        return PreRunBriefing(
            id: UUID(),
            date: Date.now,
            readinessStatus: readinessStatus,
            readinessScore: readinessScore?.overallScore,
            weather: weather,
            adaptiveAdjustment: adjustment,
            pacingRecommendation: pacingRec,
            nutritionReminder: nutritionRec,
            focusPoint: focusPoint,
            recentPerformanceSummary: performanceSummary,
            fatigueAlerts: fatiguePatterns
        )
    }

    // MARK: - Helpers

    private static func mapReadinessToRecoveryStatus(
        _ status: ReadinessStatus
    ) -> RecoveryStatus {
        switch status {
        case .primed: return .excellent
        case .ready: return .good
        case .moderate: return .moderate
        case .fatigued: return .poor
        case .needsRest: return .critical
        }
    }

    private static func buildPacingRecommendation(
        session: TrainingSession?,
        readinessScore: ReadinessScore?
    ) -> String? {
        guard let session, session.type != .rest else { return nil }

        if let readiness = readinessScore {
            switch readiness.status {
            case .primed, .ready:
                return "Good to push today. Run by feel within the planned intensity."
            case .moderate:
                return "Start conservative and assess how you feel after the first 2 km."
            case .fatigued:
                return "Keep effort easy. Focus on time on feet rather than pace."
            case .needsRest:
                return "Consider skipping this session or keeping it very light."
            }
        }

        return "No readiness data. Start easy and adjust by feel."
    }

    private static func buildNutritionReminder(
        session: TrainingSession?,
        athlete: Athlete?
    ) -> String? {
        guard let session else { return nil }
        let durationHours = session.plannedDuration / 3600
        guard durationHours >= 1.5 else { return nil }

        let weight = athlete?.weightKg ?? 70
        if durationHours >= 2 {
            let minCal = Int(weight * 4)
            let maxCal = Int(weight * 6)
            return "Run over 2 hours \u{2014} bring fuel and hydration. Aim for \(minCal)-\(maxCal) cal/hr."
        }
        return "Run over 90 min \u{2014} consider bringing water and a gel."
    }

    private static func buildFocusPoint(
        session: TrainingSession?,
        readinessScore: ReadinessScore?,
        adjustment: AdaptiveSessionAdjustment?
    ) -> String {
        if let adjustment {
            return adjustment.reasonText
        }

        guard let session else {
            return "Free run \u{2014} enjoy the movement."
        }

        switch session.type {
        case .longRun:
            return "Focus on consistent effort and practice race-day nutrition."
        case .tempo:
            return "Maintain a comfortably hard effort. You should be able to speak in short phrases."
        case .intervals:
            return "Push hard on the work intervals, recover fully between sets."
        case .verticalGain:
            return "Hike the steeps, run the flats. Focus on vertical efficiency."
        case .backToBack:
            return "Second day of back-to-back \u{2014} practice running on tired legs."
        case .recovery:
            return "Easy does it. This run is about blood flow, not fitness."
        case .crossTraining:
            return "Active recovery through cross-training. Keep it enjoyable."
        case .rest:
            return "Rest day \u{2014} recovery is when adaptation happens."
        }
    }

    private static func buildPerformanceSummary(
        recentRuns: [CompletedRun]
    ) -> String? {
        let sevenDaysAgo = Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: Date.now
        ) ?? Date.distantPast

        let lastWeekRuns = recentRuns.filter { $0.date >= sevenDaysAgo }
        guard !lastWeekRuns.isEmpty else { return nil }

        let totalKm = lastWeekRuns.reduce(0.0) { $0 + $1.distanceKm }
        let totalElev = lastWeekRuns.reduce(0.0) { $0 + $1.elevationGainM }
        let count = lastWeekRuns.count
        return "Last 7 days: \(String(format: "%.1f", totalKm)) km, \(Int(totalElev)) m D+ across \(count) runs."
    }
}
