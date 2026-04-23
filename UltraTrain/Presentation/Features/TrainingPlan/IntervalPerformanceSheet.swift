import SwiftUI

/// Inner content for the per-rep feedback page. Rendered inside the
/// SessionValidationView NavigationStack right after manual stats entry,
/// *before* the completion loading animation — athlete flow:
/// basic stats → per-rep feedback → loading → done.
///
/// Design priorities:
/// - Capture three signals (pace, effort, completion) with one tap each
/// - Hero pace comparison card — target vs editable average, quick-set
///   chips for ±3s / ±6s / on-target so a tired athlete doesn't type
/// - Per-rep detail is OPTIONAL and collapsed by default
/// - Tactile dot-row for RPE (no slider dragging when tired)
/// - Notes field stays small until tapped
struct IntervalPerformanceContent: View {

    let sessionId: UUID
    let sessionLabel: String
    let sessionType: SessionType
    let targetPacePerKm: Double
    let prescribedRepCount: Int
    let existingFeedback: IntervalPerformanceFeedback?
    let onSave: (IntervalPerformanceFeedback) -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var averageMinutes: Int = 4
    @State private var averageSeconds: Int = 0
    @State private var showPerRep: Bool = false
    @State private var perRepTexts: [String] = []
    @State private var completedAll: Bool = true
    @State private var rpe: Int = 7
    @State private var notes: String = ""
    @State private var showNotes: Bool = false
    @State private var didSeed: Bool = false

    init(
        sessionId: UUID,
        sessionLabel: String,
        sessionType: SessionType,
        targetPacePerKm: Double,
        prescribedRepCount: Int,
        existingFeedback: IntervalPerformanceFeedback? = nil,
        onSave: @escaping (IntervalPerformanceFeedback) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.sessionId = sessionId
        self.sessionLabel = sessionLabel
        self.sessionType = sessionType
        self.targetPacePerKm = targetPacePerKm
        self.prescribedRepCount = max(1, prescribedRepCount)
        self.existingFeedback = existingFeedback
        self.onSave = onSave
        self.onSkip = onSkip
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                heroPaceCard
                completionCard
                effortCard
                notesCard
            }
            .padding(Theme.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Per-rep feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") { onSkip() }
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .safeAreaInset(edge: .bottom) { saveButton }
        .onAppear(perform: seedStateIfNeeded)
    }

    // MARK: - Hero pace card

    private var heroPaceCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Target row
            HStack {
                Label("Target", systemImage: "target")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text("\(formatPace(targetPacePerKm))/km")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            // Your avg row — big and editable
            VStack(spacing: 6) {
                Text("Your average")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                HStack(spacing: 2) {
                    paceWheel($averageMinutes, range: 2..<12)
                    Text(":").font(.largeTitle.bold().monospacedDigit()).foregroundStyle(Theme.Colors.tertiaryLabel)
                    paceWheel($averageSeconds, range: 0..<60, twoDigit: true)
                    Text("/km")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.leading, 4)
                }
                .frame(height: 56)

                if let delta = currentDeltaSeconds {
                    Text(deltaLabel(delta))
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(deltaColor(delta))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(deltaColor(delta).opacity(0.12)))
                }
            }

            // Quick-set chips
            HStack(spacing: 6) {
                quickChip(label: "−6s", delta: -6)
                quickChip(label: "−3s", delta: -3)
                quickChip(label: "On target", delta: 0)
                quickChip(label: "+3s", delta: 3)
                quickChip(label: "+6s", delta: 6)
            }

            Divider().padding(.vertical, 2)

            // Per-rep expand
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showPerRep.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showPerRep ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.caption)
                    Text(showPerRep ? "Hide per-rep paces" : "Enter per-rep paces (optional)")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(Theme.Colors.warmCoral)
            }
            .buttonStyle(.plain)

            if showPerRep {
                VStack(spacing: 6) {
                    ForEach(Array(perRepTexts.indices), id: \.self) { index in
                        perRepRow(index: index)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warmCoral)
    }

    private func paceWheel(_ binding: Binding<Int>, range: Range<Int>, twoDigit: Bool = false) -> some View {
        Picker("", selection: binding) {
            ForEach(range, id: \.self) { v in
                Text(twoDigit ? String(format: "%02d", v) : "\(v)")
                    .font(.largeTitle.bold().monospacedDigit())
                    .tag(v)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(width: 70, height: 56)
        .clipped()
    }

    private func quickChip(label: String, delta: Int) -> some View {
        let newPace = targetPacePerKm + Double(delta)
        return Button {
            setPace(seconds: newPace)
        } label: {
            Text(label)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(isChipActive(delta) ? .white : Theme.Colors.label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isChipActive(delta)
                        ? Theme.Colors.warmCoral
                        : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.7)))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: completedAll ? "checkmark.seal.fill" : "seal")
                .font(.title2)
                .foregroundStyle(completedAll ? Theme.Colors.success : Theme.Colors.tertiaryLabel)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(completedAll ? "All \(prescribedRepCount) reps done" : "Bailed on some reps")
                    .font(.subheadline.weight(.semibold))
                Text(completedAll
                     ? "Tap if you dropped reps"
                     : "Incomplete reps slow the target more than pace drift alone")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Toggle("", isOn: $completedAll)
                .labelsHidden()
                .tint(Theme.Colors.success)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle()
    }

    // MARK: - Effort

    private var effortCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Label("Effort", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Text("\(rpe)/10")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(rpeColor(rpe))
            }
            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        withAnimation(.easeOut(duration: 0.12)) { rpe = value }
                    } label: {
                        Circle()
                            .fill(value <= rpe ? rpeColor(value) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.primary.opacity(0.08)))
                            .frame(height: 22)
                            .overlay(
                                Circle()
                                    .stroke(value == rpe ? rpeColor(value).opacity(0.5) : Color.clear, lineWidth: 3)
                                    .scaleEffect(1.4)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Text("Easy").font(.caption2).foregroundStyle(Theme.Colors.tertiaryLabel)
                Spacer()
                Text(rpeDescription(rpe)).font(.caption2.weight(.medium)).foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text("Max").font(.caption2).foregroundStyle(Theme.Colors.tertiaryLabel)
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showNotes.toggle() }
            } label: {
                HStack {
                    Label("Notes", systemImage: "note.text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.label)
                    Spacer()
                    Image(systemName: showNotes ? "chevron.up" : "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .buttonStyle(.plain)

            if showNotes {
                TextField("e.g. 'legs heavy from rep 3', 'windy'", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .transition(.opacity)
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle()
    }

    // MARK: - Save button

    private var saveButton: some View {
        VStack(spacing: 0) {
            Button(action: submit) {
                Label("Save feedback", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(.white)
                    .background(Theme.Gradients.warmCoralCTA)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.25), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(.regularMaterial)
    }

    // MARK: - Per-rep row

    private func perRepRow(index: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Rep \(index + 1)")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .frame(width: 56, alignment: .leading)
            TextField("m:ss", text: bindingForRep(index))
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
            Text("/km")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
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

    // MARK: - Logic helpers

    private var currentAveragePaceSeconds: Double {
        Double(averageMinutes * 60 + averageSeconds)
    }

    private var currentDeltaSeconds: Int? {
        let d = Int((currentAveragePaceSeconds - targetPacePerKm).rounded())
        return d == 0 ? nil : d
    }

    private func isChipActive(_ delta: Int) -> Bool {
        let current = Int((currentAveragePaceSeconds - targetPacePerKm).rounded())
        return current == delta
    }

    private func deltaLabel(_ delta: Int) -> String {
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta)s vs target"
    }

    private func deltaColor(_ delta: Int) -> Color {
        if abs(delta) <= 3 { return Theme.Colors.success }
        if delta < 0 { return Theme.Colors.accentColor }
        return Theme.Colors.warning
    }

    private func setPace(seconds: Double) {
        let total = Int(seconds.rounded())
        averageMinutes = max(2, min(11, total / 60))
        averageSeconds = max(0, min(59, total % 60))
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...4: return Theme.Colors.success
        case 5...6: return Theme.Colors.warning
        case 7...8: return .orange
        default:    return Theme.Colors.danger
        }
    }

    private func rpeDescription(_ value: Int) -> String {
        switch value {
        case 1...3: return "Very easy"
        case 4...5: return "Moderate"
        case 6:     return "Controlled"
        case 7:     return "Hard"
        case 8:     return "Very hard"
        case 9:     return "Nearly max"
        default:    return "All-out"
        }
    }

    private func formatPace(_ secondsPerKm: Double) -> String {
        let total = Int(secondsPerKm.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Seed & submit

    private func seedStateIfNeeded() {
        guard !didSeed else { return }
        didSeed = true
        perRepTexts = Array(repeating: "", count: prescribedRepCount)
        if let existing = existingFeedback {
            completedAll = existing.completedAllReps
            rpe = max(1, min(10, existing.perceivedEffort))
            notes = existing.notes ?? ""
            if !notes.isEmpty { showNotes = true }

            let sourcePace = existing.meanActualPacePerKm ?? existing.targetPacePerKmAtTime
            setPace(seconds: sourcePace)

            if !existing.actualPacesPerKm.isEmpty {
                showPerRep = true
                for (idx, pace) in existing.actualPacesPerKm.enumerated() where idx < perRepTexts.count {
                    perRepTexts[idx] = formatPace(pace)
                }
            }
        } else {
            setPace(seconds: targetPacePerKm)
        }
    }

    private func submit() {
        let actualPaces: [Double]
        if showPerRep {
            actualPaces = perRepTexts.prefix(prescribedRepCount).compactMap(parsePace)
        } else {
            // Replicate the athlete's declared average across the prescribed
            // reps so refinement (IR-2) still sees a pace signal — without
            // this, skipping the per-rep panel would discard pace info.
            let avg = currentAveragePaceSeconds
            actualPaces = Array(repeating: avg, count: prescribedRepCount)
        }
        let feedback = IntervalPerformanceFeedback(
            id: existingFeedback?.id ?? UUID(),
            sessionId: sessionId,
            sessionType: sessionType,
            targetPacePerKmAtTime: targetPacePerKm,
            prescribedRepCount: prescribedRepCount,
            actualPacesPerKm: actualPaces,
            completedAllReps: completedAll,
            perceivedEffort: rpe,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
            createdAt: existingFeedback?.createdAt ?? Date()
        )
        onSave(feedback)
    }

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

// MARK: - Standalone sheet wrapper

/// Presents IntervalPerformanceContent as a sheet with its own NavigationStack.
/// Kept as a convenience for callers outside SessionValidationView (the
/// primary caller now embeds the content directly in its nav flow).
struct IntervalPerformanceSheet: View {
    let sessionId: UUID
    let sessionLabel: String
    let sessionType: SessionType
    let targetPacePerKm: Double
    let prescribedRepCount: Int
    let existingFeedback: IntervalPerformanceFeedback?
    let onSave: (IntervalPerformanceFeedback) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            IntervalPerformanceContent(
                sessionId: sessionId,
                sessionLabel: sessionLabel,
                sessionType: sessionType,
                targetPacePerKm: targetPacePerKm,
                prescribedRepCount: prescribedRepCount,
                existingFeedback: existingFeedback,
                onSave: { feedback in
                    onSave(feedback)
                    dismiss()
                },
                onSkip: { dismiss() }
            )
        }
    }
}
