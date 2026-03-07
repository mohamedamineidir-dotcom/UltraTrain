import SwiftUI

struct SecondaryOnboardingButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Theme.Colors.label)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.Colors.secondaryBackground.opacity(0.8))
            .foregroundStyle(Theme.Colors.label)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.tertiaryLabel.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}
