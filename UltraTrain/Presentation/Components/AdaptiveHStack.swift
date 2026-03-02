import SwiftUI

struct AdaptiveHStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let vSpacing: CGFloat
    private let hSpacing: CGFloat
    private let content: Content

    /// Displays as HStack when in landscape (compact vertical) or on iPad (regular horizontal).
    /// Falls back to VStack on iPhone portrait.
    init(
        vSpacing: CGFloat = Theme.Spacing.md,
        hSpacing: CGFloat = Theme.Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.vSpacing = vSpacing
        self.hSpacing = hSpacing
        self.content = content()
    }

    private var useHorizontal: Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

    var body: some View {
        if useHorizontal {
            HStack(spacing: hSpacing) {
                content
            }
        } else {
            VStack(spacing: vSpacing) {
                content
            }
        }
    }
}
