#if OWNER_MODE
import Foundation

/// Editable draft of one `IntervalPhase`, shaped for form fields
/// (separate minutes/seconds, a duration/distance toggle) rather than
/// the enum-associated-value `IntervalTrigger` the domain model uses.
/// Converts both ways so the block editor can freely add/remove/edit
/// blocks and produce a plain `[IntervalPhase]` on save.
///
/// `targetPaceText`/`targetHRText` have no dedicated storage on the
/// shared `IntervalPhase` model (adding fields there would change the
/// schema for every user, not just the owner build), so they're
/// composed into `notes` as a recognizable leading line on save, and
/// parsed back out of that same line when loading an existing phase —
/// see `composedPrefix`/`parsing` below.
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
    var targetPaceText: String
    var targetHRText: String

    init(
        id: UUID = UUID(),
        phaseType: IntervalPhaseType,
        isDurationTrigger: Bool,
        minutes: Int,
        seconds: Int,
        distanceKm: Double,
        intensity: Intensity,
        repeatCount: Int,
        notes: String,
        targetPaceText: String = "",
        targetHRText: String = ""
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
        self.targetPaceText = targetPaceText
        self.targetHRText = targetHRText
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
        let parsed = Self.parseComposedLine(from: phase.notes ?? "")
        return OwnerBlockDraft(
            id: phase.id,
            phaseType: phase.phaseType,
            isDurationTrigger: isDuration,
            minutes: minutes,
            seconds: seconds,
            distanceKm: distanceKm,
            intensity: phase.targetIntensity,
            repeatCount: phase.repeatCount,
            notes: parsed.remainingNotes,
            targetPaceText: parsed.pace,
            targetHRText: parsed.hr
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
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let composed = Self.composeNotes(prefix: composedPrefix, body: trimmedNotes)
        return IntervalPhase(
            id: id,
            phaseType: phaseType,
            trigger: isDurationTrigger
                ? .duration(seconds: TimeInterval(minutes * 60 + seconds))
                : .distance(km: distanceKm),
            targetIntensity: intensity,
            repeatCount: max(1, repeatCount),
            notes: composed.isEmpty ? nil : composed
        )
    }

    // MARK: - Pace/HR <-> notes composition

    private var composedPrefix: String {
        var parts: [String] = []
        let pace = targetPaceText.trimmingCharacters(in: .whitespaces)
        let hr = targetHRText.trimmingCharacters(in: .whitespaces)
        if !pace.isEmpty { parts.append("Pace: \(pace)/km") }
        if !hr.isEmpty { parts.append("HR: \(hr) bpm") }
        return parts.joined(separator: " · ")
    }

    private static func composeNotes(prefix: String, body: String) -> String {
        guard !prefix.isEmpty else { return body }
        return body.isEmpty ? prefix : "\(prefix)\n\(body)"
    }

    /// Recognizes a first line this same composer produced (starts
    /// with "Pace:" and/or "HR:", "·"-joined) and pulls it back out;
    /// any other notes text (hand-written, or from the regular
    /// generation engine) is left untouched in `remainingNotes`.
    private static func parseComposedLine(from notes: String) -> (pace: String, hr: String, remainingNotes: String) {
        let lines = notes.components(separatedBy: "\n")
        guard let firstLine = lines.first,
              firstLine.hasPrefix("Pace:") || firstLine.hasPrefix("HR:") else {
            return ("", "", notes)
        }
        var pace = ""
        var hr = ""
        for segment in firstLine.components(separatedBy: " · ") {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Pace:") {
                pace = trimmed
                    .replacingOccurrences(of: "Pace:", with: "")
                    .replacingOccurrences(of: "/km", with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("HR:") {
                hr = trimmed
                    .replacingOccurrences(of: "HR:", with: "")
                    .replacingOccurrences(of: "bpm", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        let remaining = lines.dropFirst().joined(separator: "\n")
        return (pace, hr, remaining)
    }
}
#endif
