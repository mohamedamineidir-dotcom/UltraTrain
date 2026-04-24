import Foundation
import os

/// Exports a training plan as an RFC 5545 `.ics` calendar file that
/// the athlete can import into Apple Calendar, Google Calendar, or
/// any other iCal-compatible calendar app.
///
/// Subscription-gating is critical here: the caller must pass the
/// `visibleWeeks` produced by `TrainingPlanViewModel`, NOT the raw
/// `plan.weeks`. Otherwise a monthly subscriber could export the
/// full plan once and never renew — the gate is part of the product,
/// not an implementation detail.
///
/// All non-rest sessions become VEVENTs at 07:00 in the device's
/// current timezone, with the session's planned duration driving
/// DTEND. Coach advice is threaded into the DESCRIPTION field so the
/// notification previews in the calendar carry useful context.
enum PlanICSExporter {

    /// Writes the plan to a temporary `.ics` file and returns its URL.
    /// The temp file lives until the share sheet completes; the OS
    /// cleans up on eviction.
    static func export(
        planName: String,
        visibleWeeks: [TrainingWeek],
        hasLockedWeeks: Bool
    ) throws -> URL {
        let icsContent = buildICSString(
            planName: planName,
            visibleWeeks: visibleWeeks,
            hasLockedWeeks: hasLockedWeeks
        )
        let filename = "UltraTrain-\(ISO8601DateFormatter().string(from: .now)).ics"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        try icsContent.write(to: url, atomically: true, encoding: .utf8)
        Logger.export.info("Wrote plan .ics to \(url.lastPathComponent)")
        return url
    }

    // MARK: - Build

    private static func buildICSString(
        planName: String,
        visibleWeeks: [TrainingWeek],
        hasLockedWeeks: Bool
    ) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:-//UltraTrain//Plan Export//EN")
        lines.append("CALSCALE:GREGORIAN")
        lines.append("METHOD:PUBLISH")
        lines.append("X-WR-CALNAME:\(escape(planName))")

        for week in visibleWeeks {
            for session in week.sessions where session.type != .rest && !session.isSkipped {
                lines.append(contentsOf: buildVEvent(session: session))
            }
        }

        // When the subscription tier hides the back of the plan, leave
        // a single trailing VEVENT on the last visible day with a
        // note pointing at the locked window. Lets the athlete see
        // "something is ahead" without leaking any session data.
        if hasLockedWeeks, let lastVisible = visibleWeeks.last {
            lines.append(contentsOf: buildLockedMarkerVEvent(afterWeek: lastVisible))
        }

        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    private static func buildVEvent(session: TrainingSession) -> [String] {
        // Anchor session time at 07:00 in the device timezone. Calendar
        // apps can move these once imported; we just need a valid time.
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: session.date)
        components.hour = 7
        components.minute = 0
        let start = calendar.date(from: components) ?? session.date
        let duration = max(session.plannedDuration, 1800) // min 30 min to avoid zero-length events
        let end = start.addingTimeInterval(duration)

        let summary = summaryString(session: session)
        let description = descriptionString(session: session)
        let uid = "\(session.id.uuidString)@ultratrain.app"

        var ev: [String] = []
        ev.append("BEGIN:VEVENT")
        ev.append("UID:\(uid)")
        ev.append("DTSTAMP:\(icsDateTime(.now))")
        ev.append("DTSTART:\(icsDateTime(start))")
        ev.append("DTEND:\(icsDateTime(end))")
        ev.append("SUMMARY:\(escape(summary))")
        if !description.isEmpty {
            ev.append("DESCRIPTION:\(escape(description))")
        }
        ev.append("END:VEVENT")
        return ev
    }

    private static func buildLockedMarkerVEvent(afterWeek lastVisible: TrainingWeek) -> [String] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: lastVisible.endDate)
        components.hour = 9
        components.minute = 0
        let start = calendar.date(from: components) ?? lastVisible.endDate
        let end = start.addingTimeInterval(1800)
        let uid = "locked-\(lastVisible.id.uuidString)@ultratrain.app"

        return [
            "BEGIN:VEVENT",
            "UID:\(uid)",
            "DTSTAMP:\(icsDateTime(.now))",
            "DTSTART:\(icsDateTime(start))",
            "DTEND:\(icsDateTime(end))",
            "SUMMARY:\(escape("UltraTrain — more plan weeks available"))",
            "DESCRIPTION:\(escape("Upgrade your subscription in UltraTrain to see and export the remaining training weeks."))",
            "END:VEVENT"
        ]
    }

    // MARK: - Formatting

    private static func summaryString(session: TrainingSession) -> String {
        var parts: [String] = []
        parts.append(session.type.displayName)
        if let focus = session.intervalFocus {
            parts.append("· \(focus)")
        }
        if session.plannedDuration > 0 {
            let total = Int(session.plannedDuration)
            let h = total / 3600
            let m = (total % 3600) / 60
            let dur = h > 0 ? (m > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(h)h") : "\(m)min"
            parts.append("· \(dur)")
        }
        return parts.joined(separator: " ")
    }

    private static func descriptionString(session: TrainingSession) -> String {
        var parts: [String] = []
        if session.plannedDistanceKm > 0 {
            parts.append(String(format: "Planned: %.1f km", session.plannedDistanceKm))
        }
        if session.plannedElevationGainM > 0 {
            parts.append(String(format: "Elevation: %.0f m D+", session.plannedElevationGainM))
        }
        if !session.description.isEmpty {
            parts.append(session.description)
        }
        if let advice = session.coachAdvice, !advice.isEmpty {
            parts.append("Coach: \(advice)")
        }
        return parts.joined(separator: "\n\n")
    }

    /// RFC 5545 UTC timestamp format: 20260424T120000Z
    private static func icsDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// RFC 5545 escaping: backslash, semicolon, comma, newline.
    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
