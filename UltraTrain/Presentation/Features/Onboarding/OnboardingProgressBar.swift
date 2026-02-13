import SwiftUI

struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ProgressView(value: Double(current + 1), total: Double(total))
                .tint(Theme.Colors.primary)

            Text("Step \(current + 1) of \(total)")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }
}
