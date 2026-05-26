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
    /// Menstrual: ≥2 menstrual-cycle skips inside one 7-day window =
    /// body is signalling more than just one bad day. Suggests a soft
    /// deload framing, athlete is already dropping load via skips,
    /// this names the pattern explicitly. Informational; no auto
    /// plan mutation (the skips themselves are doing the work).
    ///
    /// This is the ONLY menstrual recommendation type. UltraTrain
    /// does not predict bleed days, ask cycle-anchor dates, or
    /// surface phase-specific cues, too intrusive for an app. The
    /// reactive flow (skip with reason → multi-skip pattern detection)
    /// is the entire surface.
    case menstrualMultiSkipPattern
    /// Race coherence: intermediate B-race is meaningfully more
    /// demanding than the A-race AND happens close enough to it
    /// that recovery isn't realistic, e.g. a 100km mountain ultra
    /// 5 weeks before a 2h40 road marathon. Flag only; the athlete
    /// keeps the priority assignment they declared, but sees the
    /// structural problem early enough to adjust either the goal,
    /// the priority, or the timing.
    case bRaceMismatch
}
