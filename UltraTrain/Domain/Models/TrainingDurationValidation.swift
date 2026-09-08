import Foundation

struct TrainingDurationValidation: Sendable {
    /// Meets the advised/optimal minimum for this category+level. Unchanged
    /// meaning from before RR-40 — only gates the soft warning, not generation.
    let isSufficient: Bool
    let availableWeeks: Int
    /// Advised/optimal minimum weeks (the original barrier, unchanged).
    let minimumWeeks: Int
    /// RR-40: half of `minimumWeeks` (rounded up, floor of 2). Below this,
    /// a plan cannot be generated at all — this is the new hard gate.
    let hardFloorWeeks: Int
    /// True when `availableWeeks >= hardFloorWeeks`. Gates onboarding
    /// advancement and plan generation. Replaces `isSufficient` as the
    /// blocking check so athletes 1-2 weeks short of the old barrier
    /// aren't turned away — they just see a warning instead.
    let canGeneratePlan: Bool
    let raceCategory: RaceCategory
    let warningMessage: String?
}
