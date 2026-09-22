#if OWNER_MODE
import Foundation

/// Owner-only, persisted (UserDefaults) toggles that feed
/// `PlanGenerationOptions.ownerBypassMinimumDuration` /
/// `ownerIncludeCurrentWeek`. Shared between the onboarding race-profile
/// step (which needs to bypass the minimum-duration gate to let the
/// owner past step 8 in the first place) and the post-onboarding
/// "Generate Plan" options sheet (which can flip the same settings
/// later, e.g. before a regeneration). Mirrors the existing
/// `DebugEntitlement` UserDefaults-toggle pattern used for `#if DEBUG`
/// QA switches.
enum OwnerModeSettings {
    private static let bypassMinimumDurationKey = "ownerMode_bypassMinimumDuration"
    static var bypassMinimumDuration: Bool {
        get { UserDefaults.standard.bool(forKey: bypassMinimumDurationKey) }
        set { UserDefaults.standard.set(newValue, forKey: bypassMinimumDurationKey) }
    }

    private static let includeCurrentWeekKey = "ownerMode_includeCurrentWeek"
    static var includeCurrentWeek: Bool {
        get { UserDefaults.standard.bool(forKey: includeCurrentWeekKey) }
        set { UserDefaults.standard.set(newValue, forKey: includeCurrentWeekKey) }
    }
}
#endif
