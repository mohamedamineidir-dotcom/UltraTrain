#if OWNER_MODE
import SwiftUI

/// Owner-only sheet for freely editing a generated session: what kind
/// of session it is, its intensity, which day it falls on, its
/// volume/duration/pace, and — for a structured interval/fractionné
/// workout — the blocks themselves (add, remove, reorder, fully
/// redefine). Diffs every field against the original session/workout
/// on save, so `onSave` only carries what actually changed.
struct OwnerSessionEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let session: TrainingSession
    let workout: IntervalWorkout?
    let weekStartDate: Date
    let weekEndDate: Date
    let onSave: (OwnerSessionEdit) -> Void

    @State private var distanceKmText: String = ""
    @State private var elevationMText: String = ""
    @State private var durationMinutesText: String = ""
    @State private var targetPaceText: String = ""
    @State private var selectedType: SessionType
    @State private var selectedIntensity: Intensity
    @State private var selectedDate: Date
    @State private var blocks: [OwnerBlockDraft]

    private let backdrop = Color(red: 0.05, green: 0.03, blue: 0.09)

    init(
        session: TrainingSession,
        workout: IntervalWorkout?,
        weekStartDate: Date,
        weekEndDate: Date,
        onSave: @escaping (OwnerSessionEdit) -> Void
    ) {
        self.session = session
        self.workout = workout
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.onSave = onSave
        _selectedType = State(initialValue: session.type)
        _selectedIntensity = State(initialValue: session.intensity)
        _selectedDate = State(initialValue: session.date)
        _blocks = State(initialValue: (workout?.phases ?? []).map(OwnerBlockDraft.from))
    }

    /// The strength-conditioning content model (bullet-point exercise
    /// list, no IntervalWorkout) is structurally different enough that
    /// this editor doesn't attempt to touch it — type-swapping and
    /// block editing are hidden for it, volume/duration still works.
    private var isStrengthConditioning: Bool { session.type == .strengthConditioning }

    var body: some View {
        NavigationStack {
            ZStack {
                backdrop.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        if !isStrengthConditioning {
                            identitySection
                        }
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
            .navigationTitle("Owner Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .tint(OwnerModeTheme.purple)
                }
            }
            .onAppear(perform: populateInitialValues)
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
                    ForEach(SessionType.allCases.filter { $0 != .strengthConditioning }, id: \.self) { type in
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

    // MARK: - Populate / Save

    private func populateInitialValues() {
        if session.plannedDistanceKm > 0 { distanceKmText = String(format: "%.2f", session.plannedDistanceKm) }
        if session.plannedElevationGainM > 0 { elevationMText = String(format: "%.0f", session.plannedElevationGainM) }
        if session.plannedDuration > 0 { durationMinutesText = String(format: "%.0f", session.plannedDuration / 60) }
    }

    private func save() {
        var edit = OwnerSessionEdit()
        edit.plannedDistanceKm = Double(distanceKmText.trimmingCharacters(in: .whitespaces))
        edit.plannedElevationGainM = Double(elevationMText.trimmingCharacters(in: .whitespaces))
        if let minutes = Double(durationMinutesText.trimmingCharacters(in: .whitespaces)) {
            edit.plannedDuration = minutes * 60
        }
        edit.targetPaceSecondsPerKm = OwnerPaceTextParser.secondsPerKm(from: targetPaceText)

        if selectedType != session.type {
            edit.newType = selectedType
        }
        if selectedIntensity != session.intensity {
            edit.newIntensity = selectedIntensity
        }
        if !Calendar.current.isDate(selectedDate, inSameDayAs: session.date) {
            edit.newDate = selectedDate
        }

        if !isStrengthConditioning {
            let newPhases = blocks.map { $0.toPhase() }
            let originalPhases = workout?.phases ?? []
            if newPhases != originalPhases {
                edit.replacementPhases = newPhases
            }
        }

        onSave(edit)
        dismiss()
    }
}
#endif
