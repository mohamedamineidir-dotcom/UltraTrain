import SwiftUI

/// Per-rep feedback capture for road intervals / tempo sessions.
///
/// Surfaced right after validating a road intervals or tempo session with a
/// structured workout attached. The athlete enters either per-rep paces or
/// uses the "hit target consistently" shortcut, confirms completion, RPE,
/// and notes. The captured data feeds IR-2 (pace refinement) — not cosmetic.
struct IntervalPerformanceSheet: View {

    let sessionId: UUID
    let sessionLabel: String
    let sessionType: SessionType
    let targetPacePerKm: Double
    let prescribedRepCount: Int
    let existingFeedback: IntervalPerformanceFeedback?
    let onSave: (IntervalPerformanceFeedback) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var hitTargetConsistently: Bool = true
    @State private var perRepTexts: [String] = []
    @State private var completedAllReps: Bool = true
    @State private var rpe: Double = 7
    @State private var notes: String = ""

    init(
        sessionId: UUID,
        sessionLabel: String,
        sessionType: SessionType,
        targetPacePerKm: Double,
        prescribedRepCount: Int,
        existingFeedback: IntervalPerformanceFeedback? = nil,
        onSave: @escaping (IntervalPerformanceFeedback) -> Void
    ) {
        self.sessionId = sessionId
        self.sessionLabel = sessionLabel
        self.sessionType = sessionType
        self.targetPacePerKm = targetPacePerKm
        self.prescribedRepCount = max(1, prescribedRepCount)
        self.existingFeedback = existingFeedback
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    targetCard
                    paceSection
                    completionSection
                    rpeSection
                    notesSection
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding()
            }
            .navigationTitle("How did the reps go?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { saveButton }
        }
        .onAppear(perform: seedFromExisting)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sessionLabel).font(.title3.bold())
            Text("Logging actual paces helps us calibrate your next sessions. Skip if you didn't time your reps.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var targetCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            targetStat(
                icon: "target",
                value: formatPace(targetPacePerKm),
                label: "Target /km"
            )
            Rectangle()
                .fill(Theme.Colors.tertiaryLabel.opacity(0.2))
                .frame(width: 1, height: 36)
            targetStat(
                icon: "repeat",
                value: "\(prescribedRepCount)",
                label: prescribedRepCount == 1 ? "Rep" : "Reps"
            )
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
    }

    private func targetStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.Colors.warmCoral)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pace section

    private var paceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Per-rep pace", systemImage: "stopwatch")

            Toggle(isOn: $hitTargetConsistently.animation()) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("I hit target consistently").font(.subheadline.weight(.medium))
                    Text("All reps within a few seconds of target.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .tint(Theme.Colors.warmCoral)

            if !hitTargetConsistently {
                ForEach(Array(perRepTexts.indices), id: \.self) { index in
                    repRow(index: index)
                }
            }
        }
    }

    private func repRow(index: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Rep \(index + 1)")
                .font(.subheadline.weight(.medium))
                .frame(width: 64, alignment: .leading)
            TextField("m:ss", text: bindingForRep(index))
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
            Text("/km")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func bindingForRep(_ index: Int) -> Binding<String> {
        Binding(
            get: { perRepTexts.indices.contains(index) ? perRepTexts[index] : "" },
            set: {
                while perRepTexts.count <= index { perRepTexts.append("") }
                perRepTexts[index] = $0
            }
        )
    }

    // MARK: - Completion

    private var completionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Completion", systemImage: "checkmark.seal")
            Toggle(isOn: $completedAllReps) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed all \(prescribedRepCount) reps").font(.subheadline.weight(.medium))
                    Text("Bailing on reps is a stronger signal than pace alone.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .tint(Theme.Colors.warmCoral)
        }
    }

    // MARK: - RPE

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Perceived effort", systemImage: "flame")
            HStack {
                Text("RPE (1 easy, 10 max)").font(.subheadline)
                Spacer()
                Text("\(Int(rpe))")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            Slider(value: $rpe, in: 1...10, step: 1)
                .tint(rpeTint(Int(rpe)))
            Text("How hard it felt matters as much as the number on the watch — we use both.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func rpeTint(_ value: Int) -> Color {
        switch value {
        case 1...4: return .green
        case 5...7: return .orange
        default: return .red
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Notes (optional)", systemImage: "note.text")
            TextField("e.g. 'felt flat from rep 3', 'windy'", text: $notes, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        VStack {
            Button(action: saveFeedback) {
                Text("Save feedback")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.warmCoral)
            .accessibilityIdentifier("interval.feedback.save")
        }
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).font(.headline)
    }

    private func seedFromExisting() {
        perRepTexts = Array(repeating: "", count: prescribedRepCount)
        guard let existing = existingFeedback else { return }
        hitTargetConsistently = existing.actualPacesPerKm.isEmpty
        completedAllReps = existing.completedAllReps
        rpe = Double(max(1, existing.perceivedEffort))
        notes = existing.notes ?? ""
        for (index, pace) in existing.actualPacesPerKm.enumerated() where index < perRepTexts.count {
            perRepTexts[index] = formatPace(pace)
        }
    }

    private func saveFeedback() {
        let actualPaces: [Double]
        if hitTargetConsistently {
            actualPaces = []
        } else {
            actualPaces = perRepTexts
                .prefix(prescribedRepCount)
                .compactMap(parsePace)
        }
        let feedback = IntervalPerformanceFeedback(
            id: existingFeedback?.id ?? UUID(),
            sessionId: sessionId,
            sessionType: sessionType,
            targetPacePerKmAtTime: targetPacePerKm,
            prescribedRepCount: prescribedRepCount,
            actualPacesPerKm: actualPaces,
            completedAllReps: completedAllReps,
            perceivedEffort: Int(rpe),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            createdAt: existingFeedback?.createdAt ?? Date()
        )
        onSave(feedback)
        dismiss()
    }

    // MARK: - Pace formatting

    private func formatPace(_ secondsPerKm: Double) -> String {
        let total = Int(secondsPerKm.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Parses "m:ss", "m.ss", or "mm:ss" into seconds/km. Returns nil for
    /// non-parseable strings so the refinement logic doesn't ingest garbage.
    private func parsePace(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ".", with: ":")
        let parts = normalized.split(separator: ":")
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]),
              minutes >= 0, seconds >= 0, seconds < 60 else {
            return nil
        }
        return Double(minutes * 60 + seconds)
    }
}
