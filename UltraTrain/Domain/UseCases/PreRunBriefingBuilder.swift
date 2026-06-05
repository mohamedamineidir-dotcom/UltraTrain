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
                return String(localized: "prebrief.pacing.ready", defaultValue: "Good to push today. Run by feel within the planned intensity.")
            case .moderate:
                return String(localized: "prebrief.pacing.moderate", defaultValue: "Start conservative and assess how you feel after the first 2 km.")
            case .fatigued:
                return String(localized: "prebrief.pacing.fatigued", defaultValue: "Keep effort easy. Focus on time on feet rather than pace.")
            case .needsRest:
                return String(localized: "prebrief.pacing.needsRest", defaultValue: "Consider skipping this session or keeping it very light.")
            }
        }

        return String(localized: "prebrief.pacing.noData", defaultValue: "No readiness data. Start easy and adjust by feel.")
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
            return String(localized: "prebrief.nutrition.over2h", defaultValue: "Run over 2 hours: bring fuel and hydration. Aim for \(minCal)-\(maxCal) cal/hr.")
        }
        return String(localized: "prebrief.nutrition.over90", defaultValue: "Run over 90 min: consider bringing water and a gel.")
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
            return String(localized: "prebrief.focus.free", defaultValue: "Free run: enjoy the movement.")
        }

        switch session.type {
        case .longRun:
            return String(localized: "prebrief.focus.longRun", defaultValue: "Focus on consistent effort and practice race-day nutrition.")
        case .tempo:
            return String(localized: "prebrief.focus.tempo", defaultValue: "Maintain a comfortably hard effort. You should be able to speak in short phrases.")
        case .intervals:
            return String(localized: "prebrief.focus.intervals", defaultValue: "Push hard on the work intervals, recover fully between sets.")
        case .verticalGain:
            return String(localized: "prebrief.focus.vg", defaultValue: "Hike the steeps, run the flats. Focus on vertical efficiency.")
        case .backToBack:
            return String(localized: "prebrief.focus.b2b", defaultValue: "Second day of back-to-back: practice running on tired legs.")
        case .recovery:
            return String(localized: "prebrief.focus.recovery", defaultValue: "Easy does it. This run is about blood flow, not fitness.")
        case .crossTraining:
            return String(localized: "prebrief.focus.crossTraining", defaultValue: "Active recovery through cross-training. Keep it enjoyable.")
        case .rest:
            return String(localized: "prebrief.focus.rest", defaultValue: "Rest day: recovery is when adaptation happens.")
        case .strengthConditioning:
            return String(localized: "prebrief.focus.strength", defaultValue: "Strength session: focus on form and controlled movement.")
        case .race:
            return String(localized: "prebrief.focus.race", defaultValue: "Race day: execute your plan, trust your fitness.")
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
        return String(localized: "prebrief.summary", defaultValue: "Last 7 days: \(String(format: "%.1f", totalKm)) km, \(Int(totalElev)) m D+ across \(count) runs.")
    }
}
