import SwiftUI

struct FeaturePreviewCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 44

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(color)
                .frame(width: 80, height: 80)
                .background(color.opacity(0.15))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
    }
}
