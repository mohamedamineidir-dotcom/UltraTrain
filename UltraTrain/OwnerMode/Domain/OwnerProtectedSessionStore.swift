#if OWNER_MODE
import Foundation

/// Tracks which sessions an owner edit has touched, persisted locally
/// (UserDefaults, same pattern as `OwnerNoteStore`/`OwnerModeSettings`).
///
/// The regular app silently auto-applies certain "urgent" adjustment
/// recommendations (`TrainingPlanViewModel.autoApplyUrgentAdjustments`)
/// — e.g. swapping a session to a recovery run, or (via
/// `.rescheduleKeySession`) moving a missed key session into the next
/// available `.rest`-typed slot it finds — entirely in the background,
/// with no banner round-trip, whenever ANY session is toggled/
/// completed/skipped. That system has no concept of "the owner
/// deliberately retyped this day," so it can silently pick an owner-
/// edited session as its target and overwrite it. This store lets the
/// auto-apply path skip any session the owner has touched.
enum OwnerProtectedSessionStore {
    private static let key = "ownerMode_protectedSessionIds"

    private static var ids: Set<UUID> {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
            return (try? JSONDecoder().decode(Set<UUID>.self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func markProtected(_ sessionId: UUID) {
        var current = ids
        current.insert(sessionId)
        ids = current
    }

    static func isProtected(_ sessionId: UUID) -> Bool {
        ids.contains(sessionId)
    }

    static func isProtected(anyOf sessionIds: [UUID]) -> Bool {
        let current = ids
        return sessionIds.contains { current.contains($0) }
    }
}
#endif
