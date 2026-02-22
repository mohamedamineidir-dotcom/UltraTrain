import SwiftUI

struct ChartAccessibilityModifier: ViewModifier {
    let summary: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(summary)
    }
}

extension View {
    func chartAccessibility(summary: String) -> some View {
        modifier(ChartAccessibilityModifier(summary: summary))
    }
}
