import SwiftUI

struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= current ? Theme.Colors.warmCoral : Theme.Colors.tertiaryLabel.opacity(0.25))
                    .frame(height: 4)
                    .shadow(color: index <= current ? Theme.Colors.warmCoral.opacity(0.5) : .clear, radius: 4)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: current)
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
        .accessibilityValue("\(AccessibilityFormatters.percentage(Double(current) * 100.0 / Double(max(total - 1, 1)))) complete")
    }
}
