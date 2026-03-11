import SwiftUI

struct PrimaryOnboardingButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled {
                        Theme.Gradients.warmCoralCTA
                    } else {
                        Theme.Colors.warmCoral.opacity(0.4)
                    }
                }
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: isEnabled ? Theme.Colors.warmCoral.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(!isEnabled || isLoading)
    }
}
