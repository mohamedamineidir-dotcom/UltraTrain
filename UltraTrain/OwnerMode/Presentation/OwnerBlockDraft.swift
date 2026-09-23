#if OWNER_MODE
import Foundation

/// Editable draft of one `IntervalPhase`, shaped for form fields
/// (separate minutes/seconds, a duration/distance toggle) rather than
/// the enum-associated-value `IntervalTrigger` the domain model uses.
/// Converts both ways so the block editor can freely add/remove/edit
/// blocks and produce a plain `[IntervalPhase]` on save.
struct OwnerBlockDraft: Identifiable, Equatable {
    var id: UUID
    var phaseType: IntervalPhaseType
    var isDurationTrigger: Bool
    var minutes: Int
    var seconds: Int
    var distanceKm: Double
    var intensity: Intensity
    var repeatCount: Int
    var notes: String

    init(
        id: UUID = UUID(),
        phaseType: IntervalPhaseType,
        isDurationTrigger: Bool,
        minutes: Int,
        seconds: Int,
        distanceKm: Double,
        intensity: Intensity,
        repeatCount: Int,
        notes: String
    ) {
        self.id = id
        self.phaseType = phaseType
        self.isDurationTrigger = isDurationTrigger
        self.minutes = minutes
        self.seconds = seconds
        self.distanceKm = distanceKm
        self.intensity = intensity
        self.repeatCount = repeatCount
        self.notes = notes
    }

    static func from(_ phase: IntervalPhase) -> OwnerBlockDraft {
        var minutes = 0, seconds = 0, distanceKm = 0.0
        let isDuration: Bool
        switch phase.trigger {
        case .duration(let s):
            isDuration = true
            minutes = Int(s) / 60
            seconds = Int(s) % 60
        case .distance(let km):
            isDuration = false
            distanceKm = km
        }
        return OwnerBlockDraft(
            id: phase.id,
            phaseType: phase.phaseType,
            isDurationTrigger: isDuration,
            minutes: minutes,
            seconds: seconds,
            distanceKm: distanceKm,
            intensity: phase.targetIntensity,
            repeatCount: phase.repeatCount,
            notes: phase.notes ?? ""
        )
    }

    static func blank(phaseType: IntervalPhaseType = .work) -> OwnerBlockDraft {
        OwnerBlockDraft(
            phaseType: phaseType,
            isDurationTrigger: true,
            minutes: 5,
            seconds: 0,
            distanceKm: 1,
            intensity: .moderate,
            repeatCount: 1,
            notes: ""
        )
    }

    func toPhase() -> IntervalPhase {
        IntervalPhase(
            id: id,
            phaseType: phaseType,
            trigger: isDurationTrigger
                ? .duration(seconds: TimeInterval(minutes * 60 + seconds))
                : .distance(km: distanceKm),
            targetIntensity: intensity,
            repeatCount: max(1, repeatCount),
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        )
    }
}
#endif
