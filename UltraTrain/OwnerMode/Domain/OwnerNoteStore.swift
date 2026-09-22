#if OWNER_MODE
import Foundation

/// Owner-only free-text notes attached to a training session, persisted
/// locally (UserDefaults) since this is personal scratch data with no
/// need to sync or survive a SwiftData schema migration. Keyed by
/// `TrainingSession.id`.
enum OwnerNoteStore {
    private static let key = "ownerMode_sessionNotes"

    private static var allNotes: [String: String] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func note(for sessionId: UUID) -> String {
        allNotes[sessionId.uuidString] ?? ""
    }

    static func setNote(_ text: String, for sessionId: UUID) {
        var notes = allNotes
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            notes.removeValue(forKey: sessionId.uuidString)
        } else {
            notes[sessionId.uuidString] = trimmed
        }
        allNotes = notes
    }
}
#endif
