import SwiftUI

struct EditRecipeSheet: View {
    let onSave: (WorkoutTemplate) -> Void
    let existingRecipe: WorkoutTemplate?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedSessionType: SessionType
    @State private var distanceKm: Double
    @State private var elevationGainM: Double
    @State private var hours: Int
    @State private var minutes: Int
    @State private var selectedIntensity: Intensity
    @State private var selectedCategory: WorkoutCategory
    @State private var descriptionText: String

    init(
        existingRecipe: WorkoutTemplate? = nil,
        onSave: @escaping (WorkoutTemplate) -> Void
    ) {
        self.onSave = onSave
        self.existingRecipe = existingRecipe

        if let recipe = existingRecipe {
            _name = State(initialValue: recipe.name)
            _selectedSessionType = State(initialValue: recipe.sessionType)
            _distanceKm = State(initialValue: recipe.targetDistanceKm)
            _elevationGainM = State(initialValue: recipe.targetElevationGainM)
            _hours = State(initialValue: Int(recipe.estimatedDuration) / 3600)
            _minutes = State(initialValue: (Int(recipe.estimatedDuration) % 3600) / 60)
            _selectedIntensity = State(initialValue: recipe.intensity)
            _selectedCategory = State(initialValue: recipe.category)
            _descriptionText = State(initialValue: recipe.descriptionText)
        } else {
            _name = State(initialValue: "")
            _selectedSessionType = State(initialValue: .longRun)
            _distanceKm = State(initialValue: 10)
            _elevationGainM = State(initialValue: 0)
            _hours = State(initialValue: 1)
            _minutes = State(initialValue: 0)
            _selectedIntensity = State(initialValue: .moderate)
            _selectedCategory = State(initialValue: .trailSpecific)
            _descriptionText = State(initialValue: "")
        }
    }

    private var availableSessionTypes: [SessionType] {
        SessionType.allCases.filter { $0 != .rest }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Workout name", text: $name)
                }

                Section("Type") {
                    Picker("Session Type", selection: $selectedSessionType) {
                        ForEach(availableSessionTypes, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Metrics") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("km", value: $distanceKm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    HStack {
                        Text("Elevation Gain")
                        Spacer()
                        TextField("m", value: $elevationGainM, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("m")
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }

                    Stepper("Hours: \(hours)", value: $hours, in: 0...12)
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 0...59)
                }

                Section("Intensity") {
                    Picker("Intensity", selection: $selectedIntensity) {
                        ForEach(Intensity.allCases, id: \.self) { intensity in
                            Text(intensity.displayName).tag(intensity)
                        }
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section("Description") {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(existingRecipe != nil ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let duration = TimeInterval(hours * 3600 + minutes * 60)
        let recipe = WorkoutTemplate(
            id: existingRecipe?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            sessionType: selectedSessionType,
            targetDistanceKm: distanceKm,
            targetElevationGainM: elevationGainM,
            estimatedDuration: duration,
            intensity: selectedIntensity,
            category: selectedCategory,
            descriptionText: descriptionText,
            isUserCreated: true
        )
        onSave(recipe)
        dismiss()
    }
}
