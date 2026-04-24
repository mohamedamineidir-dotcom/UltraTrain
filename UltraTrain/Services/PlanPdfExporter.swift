import Foundation
import UIKit
import os

/// Generates a multi-page PDF of the athlete's training plan for
/// printing, archiving, or sharing with an external coach.
///
/// Subscription-gating: iterates `visibleWeeks`, not the full
/// `plan.weeks`. If `hasLockedWeeks` is true, a closing page notes
/// how many weeks are locked without leaking any of their content.
///
/// Layout is intentionally spartan — a single-column readable
/// document with a cover + per-week sections, not a visually busy
/// export. Athletes sharing with a coach want scannable content,
/// not decorative chrome.
enum PlanPdfExporter {

    private static let pageSize = CGSize(width: 612, height: 792) // US Letter, 72dpi
    private static let margin: CGFloat = 48

    static func export(
        planName: String,
        raceName: String,
        raceDate: Date?,
        visibleWeeks: [TrainingWeek],
        hasLockedWeeks: Bool,
        lockedWeekCount: Int
    ) throws -> URL {
        let filename = "UltraTrain-\(ISO8601DateFormatter().string(from: .now)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        )
        try renderer.writePDF(to: url) { context in
            let state = RenderState()
            state.context = context
            state.newPage()

            drawCover(state: state, planName: planName, raceName: raceName, raceDate: raceDate, visibleWeeks: visibleWeeks)

            for week in visibleWeeks {
                drawWeek(state: state, week: week)
            }

            if hasLockedWeeks {
                drawLockedNotice(state: state, lockedWeekCount: lockedWeekCount)
            }
        }
        Logger.export.info("Wrote plan PDF to \(url.lastPathComponent)")
        return url
    }

    // MARK: - Render state

    /// Accumulates the cursor position across multiple draws so page
    /// breaks are handled in one place instead of scattered through
    /// every section renderer.
    private final class RenderState {
        var context: UIGraphicsPDFRendererContext?
        var cursorY: CGFloat = margin
        var pageNumber: Int = 0

        func newPage() {
            context?.beginPage()
            cursorY = margin
            pageNumber += 1
        }

        /// Ensures there's at least `height` room on the current page;
        /// starts a new page otherwise.
        func reserve(height: CGFloat) {
            if cursorY + height > pageSize.height - margin {
                newPage()
            }
        }
    }

    // MARK: - Cover

    private static func drawCover(
        state: RenderState,
        planName: String,
        raceName: String,
        raceDate: Date?,
        visibleWeeks: [TrainingWeek]
    ) {
        drawText(state: state, planName, font: .systemFont(ofSize: 28, weight: .bold), color: .label, maxWidth: contentWidth)
        state.cursorY += 8
        drawText(state: state, raceName, font: .systemFont(ofSize: 18, weight: .semibold), color: .darkGray, maxWidth: contentWidth)
        state.cursorY += 4

        var meta: [String] = []
        if let raceDate {
            meta.append("Race: \(raceDate.formatted(date: .long, time: .omitted))")
        }
        if let first = visibleWeeks.first, let last = visibleWeeks.last {
            meta.append("Plan: \(first.startDate.formatted(date: .abbreviated, time: .omitted)) — \(last.endDate.formatted(date: .abbreviated, time: .omitted))")
        }
        meta.append("\(visibleWeeks.count) weeks · \(visibleWeeks.reduce(0) { $0 + $1.sessions.count }) sessions")
        for line in meta {
            drawText(state: state, line, font: .systemFont(ofSize: 12), color: .gray, maxWidth: contentWidth)
            state.cursorY += 2
        }

        state.cursorY += 20
        drawDivider(state: state)
        state.cursorY += 12
    }

    // MARK: - Week

    private static func drawWeek(state: RenderState, week: TrainingWeek) {
        state.reserve(height: 80)

        // Week header
        let weekTitle = "Week \(week.weekNumber) · \(week.phase.displayName.capitalized)" + (week.isRecoveryWeek ? " · Recovery" : "")
        drawText(state: state, weekTitle, font: .systemFont(ofSize: 16, weight: .bold), color: .label, maxWidth: contentWidth)
        state.cursorY += 4

        let dateRange = "\(week.startDate.formatted(date: .abbreviated, time: .omitted)) — \(week.endDate.formatted(date: .abbreviated, time: .omitted))"
        drawText(state: state, dateRange, font: .systemFont(ofSize: 11), color: .gray, maxWidth: contentWidth)
        state.cursorY += 10

        // Sessions
        for session in week.sessions.sorted(by: { $0.date < $1.date }) {
            drawSession(state: state, session: session)
        }

        state.cursorY += 12
        drawDivider(state: state)
        state.cursorY += 12
    }

    private static func drawSession(state: RenderState, session: TrainingSession) {
        state.reserve(height: 60)

        let day = session.date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
        let header = summary(session: session)
        let headerLine = "\(day)  \(header)"
        drawText(state: state, headerLine, font: .systemFont(ofSize: 12, weight: .semibold), color: .label, maxWidth: contentWidth)
        state.cursorY += 2

        var metaParts: [String] = []
        if session.plannedDistanceKm > 0 {
            metaParts.append(String(format: "%.1f km", session.plannedDistanceKm))
        }
        if session.plannedDuration > 0 {
            let total = Int(session.plannedDuration)
            let h = total / 3600
            let m = (total % 3600) / 60
            metaParts.append(h > 0 ? (m > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(h)h") : "\(m)min")
        }
        if session.plannedElevationGainM > 0 {
            metaParts.append(String(format: "+%.0f m", session.plannedElevationGainM))
        }
        metaParts.append(session.intensity.displayName)
        if !metaParts.isEmpty {
            drawText(state: state, metaParts.joined(separator: " · "), font: .systemFont(ofSize: 10), color: .gray, maxWidth: contentWidth)
            state.cursorY += 2
        }

        if let advice = session.coachAdvice, !advice.isEmpty {
            drawText(state: state, advice, font: .systemFont(ofSize: 10), color: .darkGray, maxWidth: contentWidth)
        }
        state.cursorY += 8
    }

    private static func summary(session: TrainingSession) -> String {
        var s = session.type.displayName
        if let focus = session.intervalFocus { s += " · \(focus)" }
        return s
    }

    // MARK: - Locked notice

    private static func drawLockedNotice(state: RenderState, lockedWeekCount: Int) {
        state.newPage()
        state.cursorY = pageSize.height / 2 - 40
        drawText(
            state: state,
            "\(lockedWeekCount) more training \(lockedWeekCount == 1 ? "week is" : "weeks are") locked.",
            font: .systemFont(ofSize: 16, weight: .semibold),
            color: .label,
            maxWidth: contentWidth,
            alignment: .center
        )
        state.cursorY += 12
        drawText(
            state: state,
            "Upgrade your UltraTrain subscription to export the full plan.",
            font: .systemFont(ofSize: 12),
            color: .gray,
            maxWidth: contentWidth,
            alignment: .center
        )
    }

    // MARK: - Primitives

    private static var contentWidth: CGFloat { pageSize.width - margin * 2 }

    private static func drawText(
        state: RenderState,
        _ text: String,
        font: UIFont,
        color: UIColor,
        maxWidth: CGFloat,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounding = attributed.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        state.reserve(height: bounding.height + 4)
        let rect = CGRect(x: margin, y: state.cursorY, width: maxWidth, height: ceil(bounding.height))
        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        state.cursorY += ceil(bounding.height)
    }

    private static func drawDivider(state: RenderState) {
        state.reserve(height: 2)
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        cg.setStrokeColor(UIColor.separator.cgColor)
        cg.setLineWidth(0.5)
        cg.move(to: CGPoint(x: margin, y: state.cursorY))
        cg.addLine(to: CGPoint(x: pageSize.width - margin, y: state.cursorY))
        cg.strokePath()
    }
}
