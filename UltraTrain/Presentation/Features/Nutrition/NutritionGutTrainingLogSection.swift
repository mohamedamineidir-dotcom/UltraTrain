import SwiftUI

/// Collapsed summary of the gut-training sessions linked to the current
/// nutrition plan. Shows progress (logged / total), the next session, and
/// opens a dedicated sheet with the full list. Shortens the race-day
/// scroll so the plan itself is the hero of the Race Day tab.
struct NutritionGutTrainingLogSection: View {

    let sessions: [TrainingSession]
    let feedbacks: [NutritionSessionFeedback]
    let refinementNotes: [String]
    let onLogFeedback: (TrainingSession) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLog = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm + 2) {
            header
            if !refinementNotes.isEmpty {
                refinementBanner
            }
            summaryButton
        }
        .futuristicGlassStyle(phaseTint: NutritionPalette.tint)
        .sheet(isPresented: $showingLog) {
            GutTrainingLogSheet(
                sessions: sessions,
                feedbacks: feedbacks,
                onLogFeedback: { session in
                    onLogFeedback(session)
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs + 2) {
                Image(systemName: "stethoscope")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NutritionPalette.tint)
                Text("GUT TRAINING")
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

    // MARK: - Summary button

    private var summaryButton: some View {
        Button {
            showingLog = true
        } label: {
            HStack(spacing: Theme.Spacing.sm + 2) {
                progressRing
                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryLine)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.label)
                    Text(secondaryLine)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NutritionPalette.tint)
            }
            .padding(Theme.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.04)
                          : Color.white.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(NutritionPalette.tint.opacity(0.22), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("nutrition.gutTraining.openLog")
    }

    private var progressRing: some View {
        let completion: Double = sessions.isEmpty
            ? 0
            : Double(feedbacks.count) / Double(sessions.count)
        return ZStack {
            Circle()
                .stroke(NutritionPalette.tint.opacity(0.18), lineWidth: 3)
            Circle()
                .trim(from: 0, to: completion)
                .stroke(NutritionPalette.tint,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(feedbacks.count)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(NutritionPalette.tint)
        }
        .frame(width: 44, height: 44)
    }

    private var primaryLine: String {
        if sessions.isEmpty {
            return "No practice runs linked yet"
        }
        if feedbacks.count >= sessions.count {
            return "All gut-training runs logged"
        }
        return nextSessionTitle ?? "Log your feedback"
    }

    private var secondaryLine: String {
        if sessions.isEmpty {
            return "Generate a plan and we'll flag the long runs worth practicing on."
        }
        if feedbacks.count >= sessions.count {
            return "Feedback loop complete — plan refined."
        }
        return "Tap to log feedback and refine your race-day plan"
    }

    /// Nearest un-logged session label (future-dated preferred, else most recent past).
    private var nextSessionTitle: String? {
        let loggedIds = Set(feedbacks.map(\.sessionId))
        let unLogged = sessions.filter { !loggedIds.contains($0.id) }
        let next = unLogged.min { lhs, rhs in
            abs(lhs.date.timeIntervalSinceNow) < abs(rhs.date.timeIntervalSinceNow)
        }
        guard let session = next else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        let minutes = Int(session.plannedDuration / 60)
        return "Next: \(formatter.string(from: session.date)) · \(minutes) min"
    }
}

// MARK: - Log sheet

/// Full drill-down list of gut-training sessions. Tapping a row opens
/// the feedback sheet via the parent view-model flow.
private struct GutTrainingLogSheet: View {
    let sessions: [TrainingSession]
    let feedbacks: [NutritionSessionFeedback]
    let onLogFeedback: (TrainingSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm + 2) {
                    introCard
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        ForEach(sessions) { session in
                            row(for: session)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.Gradients.futuristicBackground(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle("Gut Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var introCard: some View {
        HStack(spacing: Theme.Spacing.sm + 2) {
            Image(systemName: "stethoscope")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(NutritionPalette.gradient))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(feedbacks.count) of \(sessions.count) runs logged")
                    .font(.subheadline.weight(.semibold))
                Text("Each feedback tunes your race-day plan to what your gut actually tolerates.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(NutritionPalette.tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(NutritionPalette.tint.opacity(0.22), lineWidth: 0.75)
        )
    }

    private var emptyState: some View {
        Text("No gut-training runs linked yet. Generate a plan and we'll flag the long runs worth practicing on.")
            .font(.subheadline)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
    }

    private func row(for session: TrainingSession) -> some View {
        let existing = feedbacks.first { $0.sessionId == session.id }
        let logged = existing != nil
        return Button {
            onLogFeedback(session)
            dismiss()
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
                          : Color.white.opacity(0.75))
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
