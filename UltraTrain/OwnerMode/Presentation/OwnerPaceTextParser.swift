#if OWNER_MODE
import Foundation

/// Parses a "mm:ss" or plain-minutes pace string (e.g. "5:30" or "5.5")
/// into seconds/km. Returns nil for empty/unparseable input, which the
/// caller treats as "leave unchanged."
enum OwnerPaceTextParser {
    static func secondsPerKm(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":")
            guard parts.count == 2,
                  let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else { return nil }
            return minutes * 60 + seconds
        }

        guard let minutes = Double(trimmed) else { return nil }
        return minutes * 60
    }
}
#endif
