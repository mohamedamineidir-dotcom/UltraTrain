import Foundation

enum PlanAdjustmentType: String, Sendable {
    case rescheduleKeySession
    case reduceVolumeAfterLowAdherence
    case convertToRecoveryWeek
    case bulkMarkMissedAsSkipped
    case reduceFatigueLoad
    case swapToRecovery
    case reduceLoadLowRecovery
    case swapToRecoveryLowRecovery
    case redistributeMissedVolume
    case convertEasyToQuality
    case reduceTargetDueToAccumulatedMissed
    /// Menstrual: bleed-day cluster — option-style adjustment for the
    /// next quality session in a 24-48h window.
    case menstrualBleedDayOptions
    /// Menstrual: pre-period (PMS) cluster — option-style adjustment
    /// for the hardest session in a 3-5 day window.
    case menstrualPrePeriodOptions
    /// Menstrual v2: ≥2 menstrual-cycle skips inside one 7-day window
    /// = body is signalling more than the per-session options can
    /// address. Suggests a soft deload framing — athlete is already
    /// dropping load via skips, this names the pattern explicitly.
    /// Informational; no auto plan mutation (the skips themselves
    /// are doing the work).
    case menstrualMultiSkipPattern
    /// Menstrual v2: 90+ days without a logged period while training
    /// is at normal volume = RED-S screening prompt. Soft surface to
    /// resources (Female Athlete Program, BJSM open access). Never a
    /// diagnosis. Informational only.
    case menstrualAmenorrheaScreening
    /// Menstrual v2: A-priority hard session in next 14 days falls
    /// inside the predicted symptomatic window (-3 to +2 from
    /// expected period start, based on logged cycle history). Flag
    /// only — athlete decides whether to defer / adjust on the day.
    case menstrualPredictiveFlag
    /// Race coherence: intermediate B-race is meaningfully more
    /// demanding than the A-race AND happens close enough to it
    /// that recovery isn't realistic — e.g. a 100km mountain ultra
    /// 5 weeks before a 2h40 road marathon. Flag only; the athlete
    /// keeps the priority assignment they declared, but sees the
    /// structural problem early enough to adjust either the goal,
    /// the priority, or the timing.
    case bRaceMismatch
}
