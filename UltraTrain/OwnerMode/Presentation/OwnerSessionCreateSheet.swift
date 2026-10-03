#if OWNER_MODE
import SwiftUI

/// Owner-only sheet for creating a brand-new session from scratch —
/// used for a second training on a day that already has one (e.g. a
/// morning run + an evening cross-training session). Deliberately a
/// separate, simpler sheet from `OwnerSessionEditSheet` rather than
/// retrofitting that one to an "optional session" mode: that sheet's
/// `save()` diffs every field against an existing session/workout,
/// which has nothing to diff against here — this one just builds a
/// complete `TrainingSession` outright. Shares the same sub-components
/// (block editor, day picker, pace parsing) so both sheets look and
/// behave identically.
struct OwnerSessionCreateSheet: View {
    @Environment(\.dismiss) private var dismiss

    let weekStartDate: Date
    let weekEndDate: Date
    let defaultDate: Date
    let onCreate: (TrainingSession, IntervalWorkout?) -> Void

    @State private var distanceKmText: String = ""
    @State private var elevationMText: String = ""
    @State private var durationMinutesText: String = ""
    @State private var targetPaceText: String = ""
    @State private var selectedType: SessionType = .recovery
    @State private var selectedIntensity: Intensity = .easy
    @State private var selectedDate: Date
    @State private var blocks: [OwnerBlockDraft] = []

    private let backdrop = Color(red: 0.05, green: 0.03, blue: 0.09)

    init(
        weekStartDate: Date,
        weekEndDate: Date,
        defaultDate: Date,
        onCreate: @escaping (TrainingSession, IntervalWorkout?) -> Void
    ) {
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.defaultDate = defaultDate
        self.onCreate = onCreate
        _selectedDate = State(initialValue: defaultDate)
    }

    private var isStrengthConditioning: Bool { selectedType == .strengthConditioning }

    var body: some View {
        NavigationStack {
            ZStack {
                backdrop.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        identitySection
                        volumeSection
                        if !isStrengthConditioning {
                            paceSection
                            blocksSection
                        }
                        Color.clear.frame(height: 40)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .environment(\.colorScheme, .dark)
            .presentationBackground(backdrop)
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                        .bold()
                        .tint(OwnerModeTheme.purple)
                }
            }
            .onChange(of: blocks) { _, newBlocks in
                syncVolumeFromBlocks(newBlocks)
            }
        }
    }

    private func syncVolumeFromBlocks(_ blocks: [OwnerBlockDraft]) {
        guard !blocks.isEmpty else { return }
        let totals = OwnerWorkoutBuilder.totals(for: blocks.map { $0.toPhase() })
        if totals.duration > 0 {
            durationMinutesText = String(format: "%.0f", totals.duration / 60)
        }
        if totals.distance > 0 {
            distanceKmText = String(format: "%.2f", totals.distance)
        }
    }

    // MARK: - Identity (type / intensity / day)

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(icon: "tag.fill", title: "Session")

            HStack {
                Text("Type")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .layoutPriority(1)
                Spacer(minLength: Theme.Spacing.sm)
                Menu {
                    ForEach(SessionType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            Label(type.displayName, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedType.icon)
                        Text(selectedType.displayName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(OwnerModeTheme.purple)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Intensity")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Picker("", selection: $selectedIntensity) {
                    ForEach(Intensity.allCases, id: \.self) { intensity in
                        Text(intensity.displayName).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Day this week")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                OwnerDayPicker(weekStartDate: weekStartDate, selectedDate: $selectedDate)
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: OwnerModeTheme.purple)
    }

    // MARK: - Volume

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader(icon: "chart.bar.fill", title: "Volume")
            fieldRow(label: "Distance", suffix: "km", text: $distanceKmText)
            fieldRow(label: "Elevation gain", suffix: "m", text: $elevationMText)
            fieldRow(label: "Duration", suffix: "min", text: $durationMinutesText)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: OwnerModeTheme.purple)
    }

    // MARK: - Pace

    private var paceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionHeader(icon: "speedometer", title: "Target pace")
            fieldRow(label: "Pace", suffix: "min/km", text: $targetPaceText, placeholder: "e.g. 5:30")
            Text("Setting a pace fills in distance or duration automatically from whichever one you leave blank.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: OwnerModeTheme.purple)
    }

    // MARK: - Blocks

    private var blocksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                sectionHeader(icon: "square.stack.3d.up.fill", title: "Blocks")
                Spacer(minLength: Theme.Spacing.sm)
                Button {
                    withAnimation { blocks.append(.blank()) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .tint(OwnerModeTheme.purple)
                .accessibilityLabel("Add block")
            }

            if blocks.isEmpty {
                Text("No structured blocks. Add one to build a fractionné/interval structure for this session, or leave empty for a plain run.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, _ in
                    OwnerBlockRow(
                        block: $blocks[index],
                        canMoveUp: index > 0,
                        canMoveDown: index < blocks.count - 1,
                        onMoveUp: { withAnimation { blocks.swapAt(index, index - 1) } },
                        onMoveDown: { withAnimation { blocks.swapAt(index, index + 1) } },
                        onDelete: { withAnimation { _ = blocks.remove(at: index) } }
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: OwnerModeTheme.purple)
    }

    // MARK: - Shared row builders

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(OwnerModeTheme.purple))
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(OwnerModeTheme.purple)
        }
    }

    private func fieldRow(label: String, suffix: String, text: Binding<String>, placeholder: String = "0") -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
            Spacer(minLength: Theme.Spacing.sm)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
            Text(suffix)
                .font(.caption)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
        }
    }

    // MARK: - Save

    private func save() {
        var session = TrainingSession(
            id: UUID(),
            date: selectedDate,
            type: selectedType,
            plannedDistanceKm: Double(distanceKmText.trimmingCharacters(in: .whitespaces)) ?? 0,
            plannedElevationGainM: Double(elevationMText.trimmingCharacters(in: .whitespaces)) ?? 0,
            plannedDuration: (Double(durationMinutesText.trimmingCharacters(in: .whitespaces)) ?? 0) * 60,
            intensity: selectedIntensity,
            description: "",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )

        if let pace = OwnerPaceTextParser.secondsPerKm(from: targetPaceText), pace > 0 {
            if session.plannedDuration > 0, session.plannedDistanceKm <= 0 {
                session.plannedDistanceKm = session.plannedDuration / pace
            } else if session.plannedDistanceKm > 0, session.plannedDuration <= 0 {
                session.plannedDuration = session.plannedDistanceKm * pace
            }
        }

        var workout: IntervalWorkout?
        if !isStrengthConditioning, !blocks.isEmpty {
            let phases = blocks.map { $0.toPhase() }
            let built = OwnerWorkoutBuilder.build(phases: phases, existingWorkout: nil, sessionType: selectedType)
            workout = built
            session.intervalWorkoutId = built.id
            if session.plannedDuration <= 0, built.estimatedDurationSeconds > 0 {
                session.plannedDuration = built.estimatedDurationSeconds
            }
        }

        onCreate(session, workout)
        dismiss()
    }
}
#endif
