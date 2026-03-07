import SwiftUI

enum SocialAuthProvider: String, CaseIterable {
    case apple
    case google
    case strava

    var label: String {
        switch self {
        case .apple: "Continue with Apple"
        case .google: "Continue with Google"
        case .strava: "Continue with Strava"
        }
    }

    var iconName: String {
        switch self {
        case .apple: "apple.logo"
        case .google: "g.circle.fill"
        case .strava: "figure.run"
        }
    }
}

struct SocialAuthButton: View {
    let provider: SocialAuthProvider
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    Image(systemName: provider.iconName)
                        .font(.title3)
                    Text(provider.label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch provider {
        case .apple: Color(.label)
        case .google: Theme.Colors.secondaryBackground
        case .strava: Color(red: 0.99, green: 0.30, blue: 0.08)
        }
    }

    private var foregroundColor: Color {
        switch provider {
        case .apple: Color(.systemBackground)
        case .google: Theme.Colors.label
        case .strava: .white
        }
    }

    private var borderColor: Color {
        switch provider {
        case .apple: .clear
        case .google: Theme.Colors.tertiaryLabel.opacity(0.3)
        case .strava: .clear
        }
    }
}
