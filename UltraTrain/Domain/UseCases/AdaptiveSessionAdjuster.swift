import Foundation

enum AdaptiveSessionAdjuster {

    static func adjust(
        session: TrainingSession,
        readiness: ReadinessScore?,
        recoveryScore: RecoveryScore?,
        fatiguePatterns: [FatiguePattern],
        weather: WeatherSnapshot?
    ) -> AdaptiveSessionAdjustment? {
        // Decision matrix:
        // 1. Compound fatigue -> force recovery/rest
        // 2. Hard planned + fatigued/needsRest -> downgrade to recovery
        // 3. Hard planned + moderate readiness -> reduce intensity one notch
        // 4. Easy planned + primed -> suggest upgrade to steady-state/tempo
        // 5. Any + extreme weather -> reduce intensity
        // 6. Long run + poor sleep -> reduce distance 20%

        let hasCompoundFatigue = fatiguePatterns.contains { $0.type == .compoundFatigue }
        let hasSignificantFatigue = fatiguePatterns.contains { $0.severity == .significant }
        let isHardSession = session.intensity == .hard || session.intensity == .maxEffort
            || session.type == .intervals || session.type == .tempo

        // 1. Compound / significant fatigue
        if hasCompoundFatigue || hasSignificantFatigue {
            return compoundFatigueAdjustment(for: session)
        }

        // 2-3. Readiness-based adjustments
        if let adjustment = readinessAdjustment(
            for: session,
            readiness: readiness,
            isHardSession: isHardSession
        ) {
            return adjustment
        }

        // 4. Poor sleep with long run
        if let adjustment = sleepAdjustment(for: session, recoveryScore: recoveryScore) {
            return adjustment
        }

        // 5. Extreme weather
        if let adjustment = weatherAdjustment(
            for: session,
            weather: weather,
            isHardSession: isHardSession
        ) {
            return adjustment
        }

        // No adjustment needed
        return nil
    }

    // MARK: - Compound Fatigue

    private static func compoundFatigueAdjustment(
        for session: TrainingSession
    ) -> AdaptiveSessionAdjustment {
        AdaptiveSessionAdjustment(
            id: UUID(),
            originalSessionId: session.id,
            originalType: session.type,
            originalIntensity: session.intensity,
            adjustedType: .recovery,
            adjustedIntensity: .easy,
            adjustedDistanceKm: min(session.plannedDistanceKm, 5.0),
            adjustedDuration: min(session.plannedDuration, 2400),
            reason: .compoundFatigue,
            reasonText: "Multiple fatigue signals detected. Swapping to an easy recovery session.",
            confidencePercent: 90
        )
    }

    // MARK: - Readiness

    private static func readinessAdjustment(
        for session: TrainingSession,
        readiness: ReadinessScore?,
        isHardSession: Bool
    ) -> AdaptiveSessionAdjustment? {
        guard let readiness else { return nil }

        switch readiness.status {
        case .needsRest where isHardSession:
            return AdaptiveSessionAdjustment(
                id: UUID(),
                originalSessionId: session.id,
                originalType: session.type,
                originalIntensity: session.intensity,
                adjustedType: .rest,
                adjustedIntensity: .easy,
                adjustedDistanceKm: 0,
                adjustedDuration: 0,
                reason: .readinessTooLow,
                reasonText: "Readiness is very low. Take a rest day and come back stronger.",
                confidencePercent: 85
            )

        case .fatigued where isHardSession:
            return AdaptiveSessionAdjustment(
                id: UUID(),
                originalSessionId: session.id,
                originalType: session.type,
                originalIntensity: session.intensity,
                adjustedType: .recovery,
                adjustedIntensity: .easy,
                adjustedDistanceKm: min(session.plannedDistanceKm, 8.0),
                adjustedDuration: min(session.plannedDuration, 3600),
                reason: .readinessTooLow,
                reasonText: "Readiness is low. Downgrading to an easy recovery run.",
                confidencePercent: 80
            )

        case .moderate where session.intensity == .maxEffort:
            return AdaptiveSessionAdjustment(
                id: UUID(),
                originalSessionId: session.id,
                originalType: session.type,
                originalIntensity: session.intensity,
                adjustedType: session.type,
                adjustedIntensity: .hard,
                adjustedDistanceKm: session.plannedDistanceKm * 0.9,
                adjustedDuration: session.plannedDuration * 0.9,
                reason: .readinessTooLow,
                reasonText: "Readiness is moderate. Reduced from max effort to hard.",
                confidencePercent: 70
            )

        case .primed where session.type == .recovery || session.intensity == .easy:
            return AdaptiveSessionAdjustment(
                id: UUID(),
                originalSessionId: session.id,
                originalType: session.type,
                originalIntensity: session.intensity,
                adjustedType: .tempo,
                adjustedIntensity: .moderate,
                adjustedDistanceKm: max(session.plannedDistanceKm, 8.0),
                adjustedDuration: max(session.plannedDuration, 3000),
                reason: .readinessHighUpgrade,
                reasonText: "Readiness is excellent. Upgraded to a tempo session.",
                confidencePercent: 75
            )

        default:
            return nil
        }
    }

    // MARK: - Sleep

    private static func sleepAdjustment(
        for session: TrainingSession,
        recoveryScore: RecoveryScore?
    ) -> AdaptiveSessionAdjustment? {
        guard let recovery = recoveryScore,
              recovery.sleepQualityScore < 40,
              session.type == .longRun else {
            return nil
        }

        return AdaptiveSessionAdjustment(
            id: UUID(),
            originalSessionId: session.id,
            originalType: session.type,
            originalIntensity: session.intensity,
            adjustedType: .longRun,
            adjustedIntensity: .easy,
            adjustedDistanceKm: session.plannedDistanceKm * 0.8,
            adjustedDuration: session.plannedDuration * 0.8,
            reason: .poorSleep,
            reasonText: "Sleep quality was poor. Reducing long run distance by 20%.",
            confidencePercent: 75
        )
    }

    // MARK: - Weather

    private static func weatherAdjustment(
        for session: TrainingSession,
        weather: WeatherSnapshot?,
        isHardSession: Bool
    ) -> AdaptiveSessionAdjustment? {
        guard let weather, weather.temperatureCelsius > 30, isHardSession else {
            return nil
        }

        return AdaptiveSessionAdjustment(
            id: UUID(),
            originalSessionId: session.id,
            originalType: session.type,
            originalIntensity: session.intensity,
            adjustedType: session.type,
            adjustedIntensity: session.intensity == .maxEffort ? .hard : .moderate,
            adjustedDistanceKm: session.plannedDistanceKm * 0.85,
            adjustedDuration: session.plannedDuration * 0.85,
            reason: .weatherConditions,
            reasonText: "High heat (\(Int(weather.temperatureCelsius))\u{00B0}C). Reducing intensity and volume.",
            confidencePercent: 80
        )
    }
}
