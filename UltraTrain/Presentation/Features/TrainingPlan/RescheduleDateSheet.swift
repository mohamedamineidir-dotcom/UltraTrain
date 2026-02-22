import SwiftUI

struct RescheduleDateSheet: View {
    let currentDate: Date
    let planStartDate: Date
    let planEndDate: Date
    let onReschedule: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    init(
        currentDate: Date,
        planStartDate: Date,
        planEndDate: Date,
        onReschedule: @escaping (Date) -> Void
    ) {
        self.currentDate = currentDate
        self.planStartDate = planStartDate
        self.planEndDate = planEndDate
        self.onReschedule = onReschedule
        _selectedDate = State(initialValue: currentDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Move this session to a different date")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .padding(.top, Theme.Spacing.md)

                DatePicker(
                    "New Date",
                    selection: $selectedDate,
                    in: planStartDate...planEndDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                Spacer()

                Button {
                    onReschedule(selectedDate)
                    dismiss()
                } label: {
                    Text("Reschedule")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .disabled(Calendar.current.isDate(selectedDate, inSameDayAs: currentDate))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
                .accessibilityHint("Double-tap to confirm rescheduling to the selected date")
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
