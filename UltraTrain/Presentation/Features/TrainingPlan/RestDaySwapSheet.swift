import SwiftUI

/// Dedicated sheet for moving a rest day to another day within the same
/// training week. Internally a regular swap (rest day ↔ selected session)
/// but the UX is framed as "pick when you want to rest" — which is how
/// athletes think about it — rather than "swap two sessions".
///
/// Differs from the general `SwapSessionSheet`:
///  • Scoped to THIS WEEK only (no cross-week noise)
///  • Shows each candidate as a weekday row rather than a generic list
///  • Includes the current rest day in the list (greyed out, not
///    tappable) so the athlete sees the full week at a glance
struct RestDaySwapSheet: View {
    let currentSession: TrainingSession
    /// Non-rest sessions that fall in the same calendar week as
    /// `currentSession`. Built by the caller so this view doesn't need
    /// access to the full plan.
    let weekCandidates: [SwapCandidate]
    let onSelect: (SwapCandidate) -> Void

    @Environment(\.dismiss) private var dismiss

    private var rowsByDate: [(date: Date, candidate: SwapCandidate?)] {
        let calendar = Calendar.current
        let restDay = calendar.startOfDay(for: currentSession.date)
        // Build the 7 days of the week containing the rest session.
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: restDay)?.start
            ?? calendar.date(byAdding: .day, value: -6, to: restDay) ?? restDay
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
        // Bucket each candidate into its day.
        return days.map { day in
            let candidate = weekCandidates.first { cand in
                calendar.isDate(cand.session.date, inSameDayAs: day)
            }
            return (day, candidate)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    header
                    VStack(spacing: 8) {
                        ForEach(Array(rowsByDate.enumerated()), id: \.offset) { _, row in
                            dayRow(date: row.date, candidate: row.candidate)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("Move Rest Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pick a day to rest on")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Colors.label)
            Text("The session on that day will move to \(currentSession.date.formatted(.dateTime.weekday(.wide))) in exchange.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Rows

    @ViewBuilder
    private func dayRow(date: Date, candidate: SwapCandidate?) -> some View {
        let isCurrentRest = Calendar.current.isDate(date, inSameDayAs: currentSession.date)
        if isCurrentRest {
            // Current rest day — shown greyed, not tappable, so the
            // athlete sees the full week at a glance.
            restRow(date: date)
        } else if let candidate {
            candidateButton(date: date, candidate: candidate)
        } else {
            emptyRow(date: date)
        }
    }

    private func restRow(date: Date) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            dayBadge(date: date, isCurrent: true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest (current)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("Tap another day to move")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryLabel.opacity(0.08))
        )
    }

    private func candidateButton(date: Date, candidate: SwapCandidate) -> some View {
        Button {
            onSelect(candidate)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                dayBadge(date: date, isCurrent: false)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: candidate.session.type.icon)
                            .font(.caption)
                            .foregroundStyle(candidate.session.intensity.color)
                        Text(candidate.session.type.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.label)
                    }
                    Text(metricSummary(candidate.session))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "arrow.triangle.swap")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.warmCoral)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.warmCoral.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.warmCoral.opacity(0.18), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }

    private func emptyRow(date: Date) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            dayBadge(date: date, isCurrent: false)
            Text("No session")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.tertiaryLabel.opacity(0.15), style: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
        )
    }

    private func dayBadge(date: Date, isCurrent: Bool) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.6)
                .foregroundStyle(isCurrent ? Theme.Colors.tertiaryLabel : Theme.Colors.secondaryLabel)
            Text(date.formatted(.dateTime.day()))
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(isCurrent ? Theme.Colors.tertiaryLabel : Theme.Colors.label)
        }
        .frame(width: 44)
    }

    private func metricSummary(_ session: TrainingSession) -> String {
        var parts: [String] = []
        if session.plannedDuration > 0 {
            let total = Int(session.plannedDuration)
            let h = total / 3600
            let m = (total % 3600) / 60
            parts.append(h > 0 ? (m > 0 ? "\(h)h\(String(format: "%02d", m))" : "\(h)h") : "\(m) min")
        }
        if session.plannedDistanceKm > 0 {
            parts.append(String(format: "%.1f km", session.plannedDistanceKm))
        }
        return parts.joined(separator: " · ")
    }
}
