import SwiftUI

/// Lists the gut-training long runs linked to the current nutrition plan
/// and lets the athlete log feedback on each one. Feedback accumulates into
/// the refinement loop so the race-day plan evolves toward what the athlete's
/// gut actually tolerates. Futuristic-glass treatment with the nutrition-
/// domain green tint, consistent with the rest of the Race Day tab.
struct NutritionGutTrainingLogSection: View {

    let sessions: [TrainingSession]
    let feedbacks: [NutritionSessionFeedback]
    let refinementNotes: [String]
    let onLogFeedback: (TrainingSession) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm + 2) {
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
                VStack(spacing: Theme.Spacing.xs + 2) {
                    ForEach(sessions) { session in
                        row(for: session)
                    }
                }
            }
        }
        .futuristicGlassStyle(phaseTint: NutritionPalette.tint)
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs + 2) {
                Image(systemName: "stethoscope")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NutritionPalette.tint)
                Text("GUT TRAINING LOG")
                    .font(.caption.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(NutritionPalette.tint)
            }
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
                .foregroundStyle(NutritionPalette.tint)
            ForEach(refinementNotes, id: \.self) { note in
                Text("• \(note)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(NutritionPalette.tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(NutritionPalette.tint.opacity(0.25), lineWidth: 0.75)
        )
    }

    private func row(for session: TrainingSession) -> some View {
        let existing = feedbacks.first { $0.sessionId == session.id }
        let logged = existing != nil
        return Button {
            onLogFeedback(session)
        } label: {
            HStack(spacing: Theme.Spacing.sm + 2) {
                statusIcon(session: session, hasFeedback: logged)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionTitle(session))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.label)
                    Text(sessionSubtitle(session, feedback: existing))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Image(systemName: logged ? "checkmark.circle.fill" : "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(logged ? NutritionPalette.tint : Theme.Colors.tertiaryLabel)
            }
            .padding(Theme.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.04)
                          : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        logged ? NutritionPalette.tint.opacity(0.3)
                               : Theme.Colors.tertiaryLabel.opacity(0.14),
                        lineWidth: 0.75
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(session: TrainingSession, hasFeedback: Bool) -> some View {
        let tint = statusColor(session: session, hasFeedback: hasFeedback)
        let icon: String = {
            if hasFeedback { return "checkmark" }
            if session.date < .now { return "exclamationmark" }
            return "circle"
        }()
        return Image(systemName: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(hasFeedback || session.date < .now ? .white : tint)
            .frame(width: 26, height: 26)
            .background(
                Circle().fill(
                    hasFeedback || session.date < .now
                        ? AnyShapeStyle(tint)
                        : AnyShapeStyle(tint.opacity(0.15))
                )
            )
    }

    // MARK: - Helpers

    private func statusColor(session: TrainingSession, hasFeedback: Bool) -> Color {
        if hasFeedback { return NutritionPalette.tint }
        if session.date < .now { return .orange }
        return Theme.Colors.secondaryLabel.opacity(0.5)
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
            relative = "tap to log"
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
