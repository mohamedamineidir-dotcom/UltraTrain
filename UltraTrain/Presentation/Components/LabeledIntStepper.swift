import SwiftUI

struct LabeledIntStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Button {
                value = max(range.lowerBound, value - 1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)

            Text("\(value) \(unit)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 70)
                .multilineTextAlignment(.center)

            Button {
                value = min(range.upperBound, value + 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)
        }
    }
}
