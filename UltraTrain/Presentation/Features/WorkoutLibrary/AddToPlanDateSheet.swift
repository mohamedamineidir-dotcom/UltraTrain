import SwiftUI

struct AddToPlanDateSheet: View {
    let template: WorkoutTemplate
    let onAdd: (WorkoutTemplate, Date) -> Void

    @State private var selectedDate = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                }

                Section {
                    LabeledContent("Workout", value: template.name)
                    LabeledContent("Type", value: template.sessionType.displayName)
                    LabeledContent("Intensity", value: template.intensity.displayName)
                }

                Section {
                    Button {
                        onAdd(template, selectedDate)
                        dismiss()
                    } label: {
                        Text("Add to Plan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Schedule Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
