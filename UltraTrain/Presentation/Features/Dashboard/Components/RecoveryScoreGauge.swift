import SwiftUI

struct RecoveryScoreGauge: View {
    let score: Int
    let status: RecoveryStatus

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title2.bold().monospacedDigit())
                Text(status.rawValue.capitalized)
                    .font(.system(size: 9).bold())
                    .foregroundStyle(color)
            }
        }
        .frame(width: 72, height: 72)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recovery score \(score) out of 100, \(status.rawValue)")
    }

    private var color: Color {
        switch status {
        case .excellent: Theme.Colors.success
        case .good: Theme.Colors.primary
        case .moderate: Theme.Colors.warning
        case .poor, .critical: Theme.Colors.danger
        }
    }
}
