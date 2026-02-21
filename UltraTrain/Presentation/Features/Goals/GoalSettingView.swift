import SwiftUI

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    @State private var viewModel: GoalSettingViewModel

    let onSave: (() -> Void)?

    init(goalRepository: any GoalRepository, existingGoal: TrainingGoal? = nil, onSave: (() -> Void)? = nil) {
        self.onSave = onSave
        _viewModel = State(initialValue: GoalSettingViewModel(
            goalRepository: goalRepository,
            existingGoal: existingGoal
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                periodSection
                distanceSection
                elevationSection
                runCountSection
                durationSection
            }
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.didSave {
                                onSave?()
                                dismiss()
                            }
                        }
                    }
                    .bold()
                    .disabled(viewModel.isSaving || !hasAnyTarget)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Sections

    private var periodSection: some View {
        Section {
            Picker("Period", selection: $viewModel.period) {
                Text("Weekly").tag(GoalPeriod.weekly)
                Text("Monthly").tag(GoalPeriod.monthly)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Goal Period")
        }
    }

    private var distanceSection: some View {
        Section {
            HStack {
                Text("Distance")
                Spacer()
                TextField(
                    "0",
                    value: $viewModel.targetDistanceKm,
                    format: .number.precision(.fractionLength(0...1))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                Text(UnitFormatter.distanceLabel(units))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        } header: {
            Text("Distance Target")
        } footer: {
            Text("Leave empty to skip this metric.")
        }
    }

    private var elevationSection: some View {
        Section {
            HStack {
                Text("Elevation")
                Spacer()
                TextField(
                    "0",
                    value: $viewModel.targetElevationM,
                    format: .number.precision(.fractionLength(0))
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                Text(UnitFormatter.elevationLabel(units))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        } header: {
            Text("Elevation Target")
        }
    }

    private var runCountSection: some View {
        Section {
            Stepper(
                "Runs: \(viewModel.targetRunCount ?? 0)",
                value: Binding(
                    get: { viewModel.targetRunCount ?? 0 },
                    set: { viewModel.targetRunCount = $0 > 0 ? $0 : nil }
                ),
                in: 0...30
            )
        } header: {
            Text("Run Count Target")
        }
    }

    private var durationSection: some View {
        Section {
            HStack {
                Text("Duration")
                Spacer()
                TextField(
                    "0",
                    value: $viewModel.targetDurationMinutes,
                    format: .number
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                Text("min")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        } header: {
            Text("Duration Target")
        }
    }

    // MARK: - Helpers

    private var hasAnyTarget: Bool {
        viewModel.targetDistanceKm != nil ||
        viewModel.targetElevationM != nil ||
        viewModel.targetRunCount != nil ||
        viewModel.targetDurationMinutes != nil
    }
}
