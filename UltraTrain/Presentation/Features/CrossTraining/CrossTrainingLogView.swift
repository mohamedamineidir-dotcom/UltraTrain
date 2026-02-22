import SwiftUI

struct CrossTrainingLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    @Bindable var viewModel: CrossTrainingLogViewModel

    var body: some View {
        NavigationStack {
            Form {
                activityTypeSection
                dateSection
                metricsSection
                notesSection
            }
            .navigationTitle("Log Cross-Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                    .disabled(viewModel.isSaving || viewModel.durationMinutes <= 0)
                }
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

    // MARK: - Activity Type

    private var activityTypeSection: some View {
        Section("Activity") {
            Picker("Type", selection: $viewModel.activityType) {
                ForEach(viewModel.nonRunningTypes, id: \.self) { type in
                    Label(type.displayName, systemImage: type.iconName)
                        .tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    // MARK: - Date

    private var dateSection: some View {
        Section("Date & Time") {
            DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        Section("Details") {
            Stepper(
                "Duration: \(viewModel.durationMinutes) min",
                value: $viewModel.durationMinutes,
                in: 1...600,
                step: 5
            )

            if viewModel.showDistanceField {
                HStack {
                    Text("Distance")
                    Spacer()
                    TextField(
                        "0.0",
                        value: $viewModel.distanceKm,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    Text(UnitFormatter.distanceLabel(units))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            if viewModel.showElevationField {
                HStack {
                    Text("Elevation Gain")
                    Spacer()
                    TextField(
                        "0",
                        value: $viewModel.elevationGainM,
                        format: .number.precision(.fractionLength(0))
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    Text(UnitFormatter.elevationLabel(units))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            Stepper(
                "RPE: \(viewModel.rpe) / 10",
                value: $viewModel.rpe,
                in: 1...10
            )
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Section("Notes") {
            TextField("Optional notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}
