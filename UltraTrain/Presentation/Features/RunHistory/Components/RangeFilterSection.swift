import SwiftUI

struct RangeFilterSection: View {
    let title: String
    let unitLabel: String
    @Binding var minValue: Double?
    @Binding var maxValue: Double?

    var body: some View {
        Section(title) {
            HStack(spacing: Theme.Spacing.md) {
                HStack {
                    Text("Min")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    TextField("—", value: $minValue, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Max")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    TextField("—", value: $maxValue, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                Text(unitLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }
}
