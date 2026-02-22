import SwiftUI

struct IntervalBuilderView: View {
    @Bindable var viewModel: IntervalBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                presetsSection
                phasesSection
                summarySection
            }
            .navigationTitle("Build Interval Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .sheet(isPresented: $viewModel.showPhaseEditor) {
                IntervalPhaseEditSheet(
                    existingPhase: viewModel.editingPhase,
                    onSave: { phase in
                        if viewModel.editingPhase != nil {
                            viewModel.updatePhase(phase)
                        } else {
                            viewModel.addPhase(phase)
                        }
                        viewModel.editingPhase = nil
                    }
                )
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Workout Name") {
            TextField("e.g. 5x800m Repeats", text: $viewModel.name)

            Picker("Category", selection: $viewModel.category) {
                ForEach(WorkoutCategory.allCases, id: \.self) { cat in
                    Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                }
            }
        }
    }

    private var presetsSection: some View {
        Section("Load Preset") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(IntervalWorkoutLibrary.allWorkouts) { workout in
                        Button {
                            viewModel.loadPreset(workout)
                        } label: {
                            Text(workout.name)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var phasesSection: some View {
        Section {
            if viewModel.phases.isEmpty {
                ContentUnavailableView(
                    "No Phases",
                    systemImage: "list.bullet",
                    description: Text("Add phases to build your interval workout.")
                )
            } else {
                ForEach(viewModel.phases) { phase in
                    IntervalPhaseRow(phase: phase)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.editingPhase = phase
                            viewModel.showPhaseEditor = true
                        }
                }
                .onDelete(perform: viewModel.removePhases)
                .onMove(perform: viewModel.movePhases)
            }

            Button {
                viewModel.editingPhase = nil
                viewModel.showPhaseEditor = true
            } label: {
                Label("Add Phase", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Phases")
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            LabeledContent("Work Intervals", value: "\(viewModel.workIntervalCount)")
            LabeledContent("Work:Rest Ratio", value: viewModel.workToRestRatio)
            LabeledContent("Estimated Duration", value: formatDuration(viewModel.totalEstimatedDuration))
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let min = total / 60
        return "\(min) min"
    }
}
