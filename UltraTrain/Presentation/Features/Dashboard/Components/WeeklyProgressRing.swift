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
                .stroke(Theme.Colors.secondaryLabel.opacity(0.12), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressColor.opacity(0.4), radius: 3)
                .animation(.easeInOut(duration: 0.6), value: progress)

            VStack(spacing: 0) {
                Text(percentText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text("km")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 60, height: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100)) percent of weekly distance target, \(String(format: "%.1f", actual)) of \(String(format: "%.1f", target)) kilometers")
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [progressColor.opacity(0.6), progressColor],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress)
        )
    }

    private var progressColor: Color {
        if progress >= 0.8 { return Theme.Colors.success }
        if progress >= 0.5 { return Theme.Colors.warning }
        return Theme.Colors.accentColor
    }
}
