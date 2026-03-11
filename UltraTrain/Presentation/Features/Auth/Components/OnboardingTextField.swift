import SwiftUI

struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .focused($isFocused)
        .font(.body)
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 52)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Theme.Colors.warmCoral : Theme.Colors.tertiaryLabel.opacity(0.2),
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
