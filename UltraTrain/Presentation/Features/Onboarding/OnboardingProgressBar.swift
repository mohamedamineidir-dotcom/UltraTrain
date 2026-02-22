import SwiftUI

struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    private let dotSize: CGFloat = 10
    private let activeDotSize: CGFloat = 12
    private let lineHeight: CGFloat = 2

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<total, id: \.self) { index in
                if index > 0 {
                    segmentLine(completed: index <= current)
                }
                stepDot(for: index)
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7),
            value: current
        )
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
        .accessibilityValue("\(AccessibilityFormatters.percentage(Double(current) * 100.0 / Double(max(total - 1, 1)))) complete")
    }

    @ViewBuilder
    private func stepDot(for index: Int) -> some View {
        let isActive = index == current
        let isCompleted = index < current

        Circle()
            .fill(dotColor(isActive: isActive, isCompleted: isCompleted))
            .frame(width: dotSize, height: dotSize)
            .scaleEffect(isActive ? activeDotSize / dotSize : 1.0)
    }

    private func dotColor(isActive: Bool, isCompleted: Bool) -> Color {
        if isActive || isCompleted {
            return Theme.Colors.primary
        }
        return Theme.Colors.secondaryLabel.opacity(0.3)
    }

    @ViewBuilder
    private func segmentLine(completed: Bool) -> some View {
        Rectangle()
            .fill(
                completed
                    ? Theme.Colors.primary
                    : Theme.Colors.secondaryLabel.opacity(0.3)
            )
            .frame(height: lineHeight)
    }
}
