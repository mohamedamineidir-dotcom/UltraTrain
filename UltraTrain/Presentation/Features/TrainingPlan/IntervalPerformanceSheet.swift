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
    /// Source of truth for completion: how many reps were actually
    /// finished. `completedAll` is derived from this.
    @State private var completedReps: Int = 0
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

    // MARK: - Tinted glass background

    /// Three-layer tinted-glass card background: diagonal colour tint +
    /// top-left white sheen + hairline tinted border. Same idea as the
    /// stats page, but bumped one notch stronger here because this page
    /// is deeper in the flow and the athlete has earned the richer
    /// visual language. The effort card passes a DYNAMIC tint that
    /// shifts hue as RPE changes — the whole surface changes character
    /// live as the athlete moves between green (easy) and crimson (max).
    @ViewBuilder
    private func tintedGlass(tint: Color, corner: CGFloat = Theme.CornerRadius.lg) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(LinearGradient(
                    colors: [
                        tint.opacity(colorScheme == .dark ? 0.28 : 0.14),
                        tint.opacity(colorScheme == .dark ? 0.06 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            RoundedRectangle(cornerRadius: corner)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.12 : 0.50), location: 0.0),
                        .init(color: Color.white.opacity(colorScheme == .dark ? 0.03 : 0.12), location: 0.30),
                        .init(color: Color.clear, location: 0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .allowsHitTesting(false)
        }
    }

    private func tintedGlassBorder(tint: Color, corner: CGFloat = Theme.CornerRadius.lg) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .stroke(tint.opacity(0.30), lineWidth: 0.85)
    }

    // MARK: - Hero pace card

    /// Two-column comparison: TARGET on the left (read-only), YOUR AVERAGE
    /// on the right (editable). Keeps the big digits at a comfortable
    /// 42pt so nothing dominates; the delta pill below is the visual
    /// anchor for "how close are you", and the chip row below it is for
    /// one-tap adjustment.
    private var heroPaceCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Target column
                VStack(spacing: 6) {
                    Text("TARGET")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(formatPace(targetPacePerKm))
                            .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    Text("/km")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
                .frame(maxWidth: .infinity)

                // Vertical divider
                Rectangle()
                    .fill(Theme.Colors.tertiaryLabel.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 4)

                // Your average column — tappable fields
                VStack(spacing: 6) {
                    Text("YOUR AVERAGE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(Theme.Colors.warmCoral)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        paceDigitField(
                            text: $minutesText,
                            placeholder: "4",
                            field: .minutes,
                            maxLength: 2
                        )
                        Text(":")
                            .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Theme.Colors.tertiaryLabel.opacity(0.6))
                        paceDigitField(
                            text: $secondsText,
                            placeholder: "00",
                            field: .seconds,
                            maxLength: 2,
                            zeroPad: true
                        )
                    }
                    Text("/km")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryLabel)
                }
                .frame(maxWidth: .infinity)
            }

            // Delta pill — centred, the primary comparison signal
            deltaPill

            // Quick-set chips
            HStack(spacing: 6) {
                quickChip(label: "−6s", delta: -6)
                quickChip(label: "−3s", delta: -3)
                quickChip(label: "On", delta: 0)
                quickChip(label: "+3s", delta: 3)
                quickChip(label: "+6s", delta: 6)
            }

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
        .background(tintedGlass(tint: Theme.Colors.warmCoral))
        .overlay(tintedGlassBorder(tint: Theme.Colors.warmCoral))
    }

    /// Tap-to-edit digit field. Numpad keyboard, auto zero-pad on blur
    /// for the seconds field ("3" → "03"). Compact 42pt-scale typography
    /// so the hero doesn't overwhelm.
    private func paceDigitField(
        text: Binding<String>,
        placeholder: String,
        field: PaceField,
        maxLength: Int,
        zeroPad: Bool = false
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad)
            .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(Theme.Colors.label)
            .multilineTextAlignment(.center)
            .frame(width: 52)
            .focused($focusedField, equals: field)
            .onChange(of: text.wrappedValue) { _, newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(maxLength))
                if filtered != newValue { text.wrappedValue = filtered }
            }
            .onChange(of: focusedField) { _, newValue in
                if newValue != field && zeroPad && text.wrappedValue.count == 1 {
                    text.wrappedValue = "0" + text.wrappedValue
                }
            }
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
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

    /// Interactive completion card. Toggle ON = all reps done. Toggle OFF
    /// reveals tappable pills (tap pill N to declare "I completed N reps
    /// of the prescribed total"). A partial count persists as
    /// `completedRepCount` so IR-2 can distinguish "bailed on 1 of 10"
    /// from "bailed on 5 of 10".
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
                    Text(completionHeadline)
                        .font(.subheadline.weight(.semibold))
                    Text(completionSubtitle)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { completedAll },
                    set: { newValue in
                        withAnimation(.easeOut(duration: 0.2)) {
                            completedReps = newValue ? prescribedRepCount : max(0, prescribedRepCount - 1)
                        }
                        triggerSealPulse()
                    }
                ))
                .labelsHidden()
                .tint(Theme.Colors.success)
            }

            // Tappable pill row. When all done, pills are purely decorative
            // (gradient fill). When partial, each pill is a tap target that
            // sets `completedReps = index + 1`.
            HStack(spacing: 4) {
                ForEach(0..<prescribedRepCount, id: \.self) { idx in
                    pillButton(for: idx)
                }
            }
            .animation(.easeOut(duration: 0.25), value: completedReps)

            if !completedAll {
                Text("Tap a pill to set how many you completed")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
        }
        .padding(Theme.Spacing.md)
        .background(tintedGlass(tint: completionTint))
        .overlay(tintedGlassBorder(tint: completionTint))
        .animation(.easeOut(duration: 0.3), value: completedReps)
    }

    /// Card tint flips from success-green (all done) to warning-amber
    /// (any bailed reps). Animated via the ancestor `.animation(...)` so
    /// the whole surface smoothly shifts character on toggle.
    private var completionTint: Color {
        completedAll ? Theme.Colors.success : Theme.Colors.warning
    }

    private var completedAll: Bool { completedReps >= prescribedRepCount }

    private var completionHeadline: String {
        if completedAll { return "All \(prescribedRepCount) reps done" }
        return "\(completedReps) of \(prescribedRepCount) reps done"
    }

    private var completionSubtitle: String {
        if completedAll { return "Tap toggle if you dropped reps" }
        if completedReps == 0 { return "Tap a pill to record how many you managed" }
        if completedReps == prescribedRepCount - 1 { return "Missed just the last one — noted" }
        return "Pace drift + incomplete reps = stronger slow-down signal"
    }

    @ViewBuilder
    private func pillButton(for idx: Int) -> some View {
        let filled = idx < completedReps
        let tappable = !completedAll
        Button {
            guard tappable else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                let newCount = idx + 1
                // Tapping the last filled pill while partial = decrement,
                // so the athlete can "un-set" a pill tap they made in error.
                completedReps = (completedReps == newCount && newCount < prescribedRepCount)
                                ? newCount - 1
                                : newCount
            }
        } label: {
            Capsule()
                .fill(filled
                      ? AnyShapeStyle(LinearGradient(
                          colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.75)],
                          startPoint: .leading, endPoint: .trailing))
                      : AnyShapeStyle(Theme.Colors.tertiaryLabel.opacity(0.18)))
                .frame(height: tappable ? 10 : 4)
                .overlay(
                    Capsule()
                        .stroke(tappable ? Theme.Colors.success.opacity(0.3) : Color.clear, lineWidth: 0.75)
                )
        }
        .buttonStyle(.plain)
        .disabled(!tappable)
    }

    private func triggerSealPulse() {
        sealPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { sealPulse = false }
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
        .background(tintedGlass(tint: rpeGradientColor(rpe)))
        .overlay(tintedGlassBorder(tint: rpeGradientColor(rpe)))
        .animation(.easeOut(duration: 0.25), value: rpe)
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
        .background(tintedGlass(tint: Theme.Colors.accentColor))
        .overlay(tintedGlassBorder(tint: Theme.Colors.accentColor))
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

    /// Hand-curated 10-colour palette. Linear HSL interpolation across
    /// hue 120°→0° passed through the muddy yellow-green band (hue 50-80°)
    /// and looked ugly. Here we jump from a deep mint-green at RPE 4 to
    /// a vivid amber at RPE 5, skipping the ugly band entirely, and
    /// continue through deep orange into crimson. Every step is visually
    /// distinct and each colour feels intentional, not interpolated.
    private func rpeGradientColor(_ value: Int) -> Color {
        let palette: [(r: Double, g: Double, b: Double)] = [
            (0.22, 0.80, 0.68),  // 1 — cyan-mint
            (0.24, 0.78, 0.56),  // 2 — mint
            (0.32, 0.78, 0.44),  // 3 — vivid green
            (0.46, 0.78, 0.32),  // 4 — deep green (last cool shade before warm jump)
            (0.95, 0.70, 0.22),  // 5 — amber (skips yellow-green mud)
            (0.98, 0.56, 0.18),  // 6 — bright orange
            (1.00, 0.42, 0.18),  // 7 — vivid orange
            (0.96, 0.28, 0.24),  // 8 — red-orange
            (0.88, 0.20, 0.32),  // 9 — crimson
            (0.72, 0.16, 0.44)   // 10 — deep crimson-magenta
        ]
        let index = max(1, min(10, value)) - 1
        let c = palette[index]
        return Color(red: c.r, green: c.g, blue: c.b)
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
        completedReps = prescribedRepCount   // default: all done
        if let existing = existingFeedback {
            // Prefer the granular count when present; fall back to the
            // boolean for legacy records.
            if let count = existing.completedRepCount {
                completedReps = min(count, prescribedRepCount)
            } else {
                completedReps = existing.completedAllReps ? prescribedRepCount : 0
            }
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
            completedRepCount: completedReps,
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
