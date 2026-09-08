import SwiftUI

/// RR-40: shown when the plan was generated with fewer weeks than our
/// advised minimum for the race's distance/experience tier (but at or
/// above the new hard floor). Purely informational, not a warning about
/// something wrong with the plan itself — explains why base/build got
/// compressed so the athlete isn't confused by the shorter progression.
struct CompressedPrepBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    private var tint: Color { Theme.Colors.info }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text("Compressed Preparation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
                Text("You have fewer weeks than we'd normally recommend for this race, so this plan prioritizes race-specific work and your taper over a full base-building block.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(tint.opacity(colorScheme == .dark ? 0.16 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(tint.opacity(0.25), lineWidth: 0.75)
        )
    }
}
