import SwiftUI

/// Shared section-header style. One look across the app: tracked all-
/// caps title in secondary grey, plus a short animated gradient
/// underline that fades into the surrounding content. The gradient
/// adopts the optional tint so a feature can colour-code its sections
/// (training coral, nutrition green, progress info-cyan) without
/// breaking the family.
///
/// Replaces the bespoke `DashboardSectionHeader` and the ad-hoc
/// `Text(title).font(.headline)` patterns scattered through Progress
/// and Training-plan sections.
struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    var tint: Color = Theme.Colors.accentColor

    @State private var lineWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                }
                Text(title.uppercased())
                    .font(.caption.bold())
                    .tracking(Theme.LetterSpacing.tracked)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [tint, tint.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: lineWidth, height: 1.5)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        lineWidth = 60
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.lg)
    }
}
