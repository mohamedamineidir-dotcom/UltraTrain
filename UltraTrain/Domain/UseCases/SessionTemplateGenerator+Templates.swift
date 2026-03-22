import Foundation

// MARK: - Legacy API Compatibility

extension SessionTemplateGenerator {

    // These methods are kept for backward compatibility with existing callers
    // that pass the old-style parameters. They delegate to the new volume-based API.

    static func phaseTemplates(
        for phase: TrainingPhase,
        experience: ExperienceLevel,
        raceEffectiveKm: Double,
        weekInPhase: Int
    ) -> [SessionTemplate] {
        // Build a minimal volume for backward compat (used by override templates)
        let defaultDurations = VolumeCalculator.BaseSessionDurations(
            easyRun1Seconds: 2700,
            easyRun2Seconds: 2700,
            intervalSeconds: 3000,
            vgSeconds: 3000
        )
        let defaultVolume = VolumeCalculator.WeekVolume(
            weekNumber: 0,
            targetVolumeKm: 0,
            targetElevationGainM: 0,
            targetDurationSeconds: 0,
            targetLongRunDurationSeconds: 7200,
            isB2BWeek: false,
            b2bDay1Seconds: 0,
            b2bDay2Seconds: 0,
            baseSessionDurations: defaultDurations,
            weekNumberInTaper: 0,
            taperProfile: nil
        )
        return phaseTemplates(
            for: phase,
            volume: defaultVolume,
            experience: experience,
            weekNumberInPhase: weekInPhase
        )
    }

    static func recoveryTemplates(experience: ExperienceLevel) -> [SessionTemplate] {
        let defaultDurations = VolumeCalculator.BaseSessionDurations(
            easyRun1Seconds: 2700,
            easyRun2Seconds: 2700,
            intervalSeconds: 3000,
            vgSeconds: 3000
        )
        let defaultVolume = VolumeCalculator.WeekVolume(
            weekNumber: 0,
            targetVolumeKm: 0,
            targetElevationGainM: 0,
            targetDurationSeconds: 0,
            targetLongRunDurationSeconds: 5400,
            isB2BWeek: false,
            b2bDay1Seconds: 0,
            b2bDay2Seconds: 0,
            baseSessionDurations: defaultDurations,
            weekNumberInTaper: 0,
            taperProfile: nil
        )
        return recoveryTemplates(volume: defaultVolume)
    }

    // MARK: - Cross-Training Helper (kept for potential future use)

    static func crossTrainingOrAlternative(
        day: Int,
        experience: ExperienceLevel,
        isRecoveryWeek: Bool = false
    ) -> SessionTemplate {
        switch experience {
        case .elite:
            return tpl(day, .crossTraining, .easy, 2700, 0,
                "Cross-training: cycling, swimming, or hiking. Active recovery.")
        case .advanced where isRecoveryWeek:
            return tpl(day, .crossTraining, .easy, 2700, 0,
                "Light cross-training: swimming, yoga, or gentle cycling.")
        case .advanced:
            return tpl(day, .recovery, .easy, 2400, 0,
                "Easy recovery run. Keep the pace conversational.")
        case .beginner, .intermediate:
            return tpl(day, .rest, .easy, 0, 0,
                "Rest day. Recovery is part of training.")
        }
    }
}
