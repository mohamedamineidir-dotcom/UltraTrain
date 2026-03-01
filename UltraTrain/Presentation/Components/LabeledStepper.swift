import SwiftUI

struct LabeledStepper: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isFocused: Bool

    private var specifier: String {
        step >= 1 ? "%.0f" : "%.1f"
    }

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

            if isEditing {
                TextField("", text: $editText)
                    .keyboardType(.decimalPad)
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 70)
                    .focused($isFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commitEdit() }
                    }
            } else {
                Text("\(value, specifier: specifier) \(unit)")
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 70)
                    .multilineTextAlignment(.center)
                    .contentShape(Rectangle())
                    .onTapGesture { beginEdit() }
            }

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value, specifier: specifier) \(unit)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }

    private func beginEdit() {
        editText = String(format: specifier, value)
        isEditing = true
        isFocused = true
    }

    private func commitEdit() {
        if let parsed = Double(editText) {
            value = min(range.upperBound, max(range.lowerBound, parsed))
        }
        isEditing = false
    }
}
