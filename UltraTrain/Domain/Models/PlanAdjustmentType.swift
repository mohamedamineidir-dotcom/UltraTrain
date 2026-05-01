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
}
