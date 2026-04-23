import SwiftUI

/// Inner content for the per-rep feedback page. Rendered inside
/// SessionValidationView's NavigationStack right after the manual stats
/// entry — flow: basic stats → per-rep feedback → loading → done.
///
/// Design priorities:
/// - Capture three signals (pace, effort, completion) with minimum taps
/// - Hero pace card shows target + your average side-by-side with
///   DIRECTLY-TAPPABLE digit fields (no wheel pickers). Live delta pill
///   and quick chips for one-tap common deltas.
/// - Completion: toggle with a visual pill strip (one pill per prescribed
///   rep) so the athlete sees their count shift in real time.
/// - Effort: 10 dots each with its own hue along the green→red gradient
///   so every step feels distinct.
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
    @FocusState private var focusedField: PaceField?

    enum PaceField: Hashable { case minutes, seconds }

    @State private var minutesText: String = ""
    @State private var secondsText: String = ""
    @State private var showPerRep: Bool = false
    @State private var perRepTexts: [String] = []
    @State private var completedAll: Bool = true
    @State private var rpe: Int = 7
    @State private var notes: String = ""
    @State private var showNotes: Bool = false
    @State private var didSeed: Bool = false
    @State private var sealPulse: Bool = false

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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .safeAreaInset(edge: .bottom) { saveButton }
        .onAppear(perform: seedStateIfNeeded)
    }

    // MARK: - Hero pace card

    private var heroPaceCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Target chip row
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.warmCoral)
                Text("Target")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text("\(formatPace(targetPacePerKm))/km")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            // Big editable pace
            VStack(spacing: 8) {
                Text("YOUR AVERAGE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    paceDigitField(
                        text: $minutesText,
                        placeholder: "4",
                        field: .minutes,
                        maxLength: 2
                    )
                    Text(":")
                        .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.Colors.tertiaryLabel.opacity(0.6))
                        .padding(.horizontal, 2)
                    paceDigitField(
                        text: $secondsText,
                        placeholder: "00",
                        field: .seconds,
                        maxLength: 2,
                        zeroPad: true
                    )
                    Text("/km")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.leading, 6)
                        .padding(.bottom, 6)
                }

                deltaPill
            }
            .padding(.vertical, 4)

            // Quick-set chips
            HStack(spacing: 6) {
                quickChip(label: "−6s", delta: -6)
                quickChip(label: "−3s", delta: -3)
                quickChip(label: "On", delta: 0)
                quickChip(label: "+3s", delta: 3)
                quickChip(label: "+6s", delta: 6)
            }

            Divider().padding(.vertical, 2)

            // Per-rep expand
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showPerRep.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showPerRep ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
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
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(LinearGradient(
                    colors: [
                        Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.14 : 0.06),
                        Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.04 : 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.warmCoral.opacity(0.22), lineWidth: 0.75)
        )
    }

    /// Tap-to-edit digit field with big monospaced digits. Focusing brings
    /// up the numeric keypad; losing focus zero-pads seconds so "3" → "03"
    /// automatically.
    private func paceDigitField(
        text: Binding<String>,
        placeholder: String,
        field: PaceField,
        maxLength: Int,
        zeroPad: Bool = false
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .font(.system(size: 54, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(Theme.Colors.label)
            .multilineTextAlignment(.center)
            .frame(width: 84)
            .focused($focusedField, equals: field)
            .onChange(of: text.wrappedValue) { _, newValue in
                // Keep to digits and clamp length.
                let filtered = String(newValue.filter(\.isNumber).prefix(maxLength))
                if filtered != newValue { text.wrappedValue = filtered }
            }
            .onChange(of: focusedField) { _, newValue in
                if newValue != field && zeroPad {
                    if text.wrappedValue.count == 1 {
                        text.wrappedValue = "0" + text.wrappedValue
                    }
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(focusedField == field
                          ? Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.15 : 0.08)
                          : Color.clear)
            )
            .animation(.easeOut(duration: 0.15), value: focusedField)
    }

    @ViewBuilder
    private var deltaPill: some View {
        let delta = currentDeltaSeconds
        HStack(spacing: 4) {
            Image(systemName: delta == 0 ? "checkmark.circle.fill"
                              : (delta > 0 ? "arrow.down.right" : "arrow.up.right"))
                .font(.caption2.weight(.bold))
            Text(deltaLabel(delta))
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(deltaColor(delta))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(deltaColor(delta).opacity(colorScheme == .dark ? 0.18 : 0.12))
        )
    }

    private func quickChip(label: String, delta: Int) -> some View {
        let isActive = isChipActive(delta)
        return Button {
            setPaceFromDelta(delta)
        } label: {
            Text(label)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(isActive ? .white : Theme.Colors.label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isActive
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Theme.Colors.warmCoral, Theme.Colors.warmCoral.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        : AnyShapeStyle(colorScheme == .dark
                                        ? Color.white.opacity(0.08)
                                        : Color.primary.opacity(0.05))
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: completedAll ? "checkmark.seal.fill" : "seal")
                    .font(.title2)
                    .foregroundStyle(completedAll ? Theme.Colors.success : Theme.Colors.tertiaryLabel)
                    .scaleEffect(sealPulse ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: sealPulse)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(completedAll ? "All \(prescribedRepCount) reps done" : "Bailed on some reps")
                        .font(.subheadline.weight(.semibold))
                    Text(completedAll
                         ? "Tap if you dropped reps"
                         : "Incomplete reps is a stronger slow-down signal than pace drift")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Toggle("", isOn: $completedAll)
                    .labelsHidden()
                    .tint(Theme.Colors.success)
                    .onChange(of: completedAll) { _, _ in
                        sealPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { sealPulse = false }
                    }
            }

            // Visual strip — one pill per rep, fills when completedAll=true,
            // shows a subtle unfilled state when not. Gives the athlete a
            // tactile sense of the count.
            HStack(spacing: 4) {
                ForEach(0..<prescribedRepCount, id: \.self) { _ in
                    Capsule()
                        .fill(completedAll
                              ? AnyShapeStyle(LinearGradient(
                                  colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.75)],
                                  startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Theme.Colors.tertiaryLabel.opacity(0.2)))
                        .frame(height: 4)
                }
            }
            .animation(.easeOut(duration: 0.25), value: completedAll)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.tertiaryLabel.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Effort

    private var effortCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(rpeGradientColor(rpe))
                Text("Effort")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                HStack(spacing: 2) {
                    Text("\(rpe)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(rpeGradientColor(rpe))
                    Text("/10")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
            }

            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        withAnimation(.easeOut(duration: 0.12)) { rpe = value }
                    } label: {
                        ZStack {
                            // Outer glow for the active dot only
                            if value == rpe {
                                Circle()
                                    .fill(rpeGradientColor(value).opacity(0.28))
                                    .frame(width: 34, height: 34)
                                    .blur(radius: 5)
                            }
                            Circle()
                                .fill(value <= rpe
                                      ? AnyShapeStyle(LinearGradient(
                                          colors: [
                                              rpeGradientColor(value),
                                              rpeGradientColor(value).opacity(0.75)
                                          ],
                                          startPoint: .topLeading,
                                          endPoint: .bottomTrailing))
                                      : AnyShapeStyle(colorScheme == .dark
                                                      ? Color.white.opacity(0.06)
                                                      : Color.primary.opacity(0.06)))
                                .frame(width: value == rpe ? 26 : 22, height: value == rpe ? 26 : 22)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(value == rpe ? 0.6 : 0), lineWidth: 1.5)
                                )
                        }
                        .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text("Easy").font(.caption2).foregroundStyle(Theme.Colors.tertiaryLabel)
                Spacer()
                Text(rpeDescription(rpe))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(rpeGradientColor(rpe))
                    .animation(.easeOut(duration: 0.15), value: rpe)
                Spacer()
                Text("Max").font(.caption2).foregroundStyle(Theme.Colors.tertiaryLabel)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.tertiaryLabel.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showNotes.toggle() }
            } label: {
                HStack {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    Text("Notes")
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
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.tertiaryLabel.opacity(0.12), lineWidth: 0.5)
        )
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
        let mins = Int(minutesText) ?? 0
        let secs = Int(secondsText) ?? 0
        return Double(mins * 60 + secs)
    }

    private var currentDeltaSeconds: Int {
        Int((currentAveragePaceSeconds - targetPacePerKm).rounded())
    }

    private func isChipActive(_ delta: Int) -> Bool {
        currentDeltaSeconds == delta
    }

    private func deltaLabel(_ delta: Int) -> String {
        if delta == 0 { return "On target" }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta)s vs target"
    }

    private func deltaColor(_ delta: Int) -> Color {
        if delta == 0 { return Theme.Colors.success }
        if abs(delta) <= 3 { return Theme.Colors.success }
        if delta < 0 { return Theme.Colors.accentColor }
        return Theme.Colors.warning
    }

    private func setPaceFromDelta(_ delta: Int) {
        let total = Int((targetPacePerKm + Double(delta)).rounded())
        let mins = max(0, total / 60)
        let secs = max(0, min(59, total % 60))
        minutesText = "\(mins)"
        secondsText = String(format: "%02d", secs)
    }

    /// Interpolates hue along green (120°) → red (0°) so each of the 10
    /// dots gets its own distinct shade. Avoids the "4 greens + 4 oranges
    /// + 2 reds" flatness of a switch-based approach.
    private func rpeGradientColor(_ value: Int) -> Color {
        let clamped = max(1, min(10, value))
        let t = Double(clamped - 1) / 9.0                 // 0.0 → 1.0
        let hue = (120.0 - t * 120.0) / 360.0             // green → red
        let saturation: Double = 0.78
        let brightness: Double = 0.82 - t * 0.12          // slightly deepen toward red
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func rpeDescription(_ value: Int) -> String {
        switch value {
        case 1...2: return "Very easy"
        case 3:     return "Easy"
        case 4:     return "Moderate"
        case 5:     return "Steady"
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
            setPaceDirect(seconds: sourcePace)

            if !existing.actualPacesPerKm.isEmpty {
                showPerRep = true
                for (idx, pace) in existing.actualPacesPerKm.enumerated() where idx < perRepTexts.count {
                    perRepTexts[idx] = formatPace(pace)
                }
            }
        } else {
            setPaceDirect(seconds: targetPacePerKm)
        }
    }

    private func setPaceDirect(seconds: Double) {
        let total = Int(seconds.rounded())
        minutesText = "\(max(0, total / 60))"
        secondsText = String(format: "%02d", max(0, min(59, total % 60)))
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
