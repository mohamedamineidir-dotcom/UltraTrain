import SwiftUI

struct RunHistoryFilterBar: View {
    @Binding var selectedPeriod: RunTimePeriod
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Picker("Time Period", selection: $selectedPeriod) {
                ForEach(RunTimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if selectedPeriod == .custom {
                customDateRange
            }
        }
    }

    private var customDateRange: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("From")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                DatePicker(
                    "Start",
                    selection: $customStartDate,
                    in: ...customEndDate,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("To")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                DatePicker(
                    "End",
                    selection: $customEndDate,
                    in: customStartDate...,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
        }
    }
}
