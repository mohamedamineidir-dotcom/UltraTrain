import SwiftUI

struct GutTrainingBadge: View {
    /// Icon-only, no text — for tight horizontal contexts (the weekly
    /// session list row) where the full pill has no room to grow
    /// without squeezing a sibling label into wrapping instead (which
    /// is what inflated that one day's row height). The full pill
    /// remains the default for roomier contexts (dashboard, nutrition
    /// detail) where the text is worth keeping.
    var compact: Bool = false

    var body: some View {
        Group {
            if compact {
                Image(systemName: "fork.knife")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(4)
                    .background(Circle().fill(Theme.Colors.primary.opacity(0.12)))
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "fork.knife")
                    Text("Gut Training")
                        .font(.caption2.bold())
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(Theme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 2)
                .background(Theme.Colors.primary.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gut training recommended")
    }
}
