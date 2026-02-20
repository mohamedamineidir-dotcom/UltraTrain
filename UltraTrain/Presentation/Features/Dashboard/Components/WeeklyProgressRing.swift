import SwiftUI

struct WeeklyProgressRing: View {
    let actual: Double
    let target: Double

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(actual / target, 1.0)
    }

    private var percentText: String {
        "\(Int(progress * 100))%"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.secondaryLabel.opacity(0.2), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            VStack(spacing: 0) {
                Text(percentText)
                    .font(.system(.caption, design: .rounded).bold())
                Text("km")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 60, height: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100)) percent of weekly distance target, \(String(format: "%.1f", actual)) of \(String(format: "%.1f", target)) kilometers")
    }

    private var progressColor: Color {
        if progress >= 0.8 { return Theme.Colors.success }
        if progress >= 0.5 { return Theme.Colors.warning }
        return Theme.Colors.primary
    }
}
