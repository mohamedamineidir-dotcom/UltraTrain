import SwiftUI

/// Lists the gut-training long runs linked to the current nutrition plan
/// and lets the athlete log feedback on each one. Feedback accumulates into
/// the refinement loop so the race-day plan evolves toward what the athlete's
/// gut actually tolerates.
struct NutritionGutTrainingLogSection: View {

    let sessions: [TrainingSession]
    let feedbacks: [NutritionSessionFeedback]
    let refinementNotes: [String]
    let onLogFeedback: (TrainingSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header

            if !refinementNotes.isEmpty {
                refinementBanner
            }

            if sessions.isEmpty {
                Text("No gut-training runs linked yet. Generate a plan and we'll flag the long runs worth practicing on.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(sessions) { session in
                    row(for: session)
                }
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Label("Gut training log", systemImage: "stethoscope")
                .font(.headline)
            Spacer()
            Text("\(feedbacks.count) / \(sessions.count) logged")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var refinementBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Plan refined from your training", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Colors.accentColor)
            ForEach(refinementNotes, id: \.self) { note in
                Text("• \(note)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    private func row(for session: TrainingSession) -> some View {
        let existing = feedbacks.first { $0.sessionId == session.id }
        return Button {
            onLogFeedback(session)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Status dot
                Circle()
                    .fill(statusColor(session: session, hasFeedback: existing != nil))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionTitle(session))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Colors.label)
                    Text(sessionSubtitle(session, feedback: existing))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                Image(systemName: existing != nil ? "checkmark.circle.fill" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(existing != nil ? Theme.Colors.success : Theme.Colors.secondaryLabel)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func statusColor(session: TrainingSession, hasFeedback: Bool) -> Color {
        if hasFeedback { return Theme.Colors.success }
        if session.date < .now { return Theme.Colors.warning }
        return Theme.Colors.secondaryLabel.opacity(0.4)
    }

    private func sessionTitle(_ session: TrainingSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        let minutes = Int(session.plannedDuration / 60)
        return "\(formatter.string(from: session.date)) · \(minutes) min"
    }

    private func sessionSubtitle(
        _ session: TrainingSession,
        feedback: NutritionSessionFeedback?
    ) -> String {
        if let feedback {
            return "\(feedback.actualCarbsConsumed) g/hr actual · max GI \(feedback.maxSymptom)"
        }
        let relative: String
        if session.date < .now {
            relative = "logged?"
        } else {
            let days = Calendar.current.dateComponents([.day], from: .now, to: session.date).day ?? 0
            relative = days == 0 ? "today" : (days == 1 ? "tomorrow" : "in \(days)d")
        }
        return "Practice race fueling · \(relative)"
    }
}

private extension NutritionSessionFeedback {
    var maxSymptom: Int {
        max(max(nausea, bloating), max(cramping, urgency))
    }
}
