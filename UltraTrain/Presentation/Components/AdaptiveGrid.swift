import SwiftUI

struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let spacing: CGFloat
    private let content: Content

    init(spacing: CGFloat = Theme.Spacing.md, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content
        }
    }
}
