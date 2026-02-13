import SwiftUI

struct LabeledStepper: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)

            Text("\(value, specifier: step >= 1 ? "%.0f" : "%.1f") \(unit)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 70)
                .multilineTextAlignment(.center)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)
        }
    }
}
