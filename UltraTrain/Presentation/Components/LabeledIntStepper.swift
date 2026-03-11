import SwiftUI

struct LabeledIntStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.subheadline)
                .fixedSize()
            Spacer(minLength: 2)
            Button {
                value = max(range.lowerBound, value - 1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)

            if isEditing {
                TextField("", text: $editText)
                    .keyboardType(.numberPad)
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 44)
                    .focused($isFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commitEdit() }
                    }
            } else {
                Text("\(value) \(unit)")
                    .font(.body.monospacedDigit())
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)
                    .contentShape(Rectangle())
                    .onTapGesture { beginEdit() }
            }

            Button {
                value = min(range.upperBound, value + 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.Colors.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value) \(unit)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + 1)
            case .decrement:
                value = max(range.lowerBound, value - 1)
            @unknown default:
                break
            }
        }
    }

    private func beginEdit() {
        editText = "\(value)"
        isEditing = true
        isFocused = true
    }

    private func commitEdit() {
        if let parsed = Int(editText) {
            value = min(range.upperBound, max(range.lowerBound, parsed))
        }
        isEditing = false
    }
}
