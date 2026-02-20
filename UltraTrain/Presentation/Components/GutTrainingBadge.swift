import SwiftUI

struct GutTrainingBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "fork.knife")
            Text("Gut Training")
                .font(.caption2.bold())
        }
        .foregroundStyle(Theme.Colors.primary)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(Theme.Colors.primary.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gut training recommended")
    }
}
