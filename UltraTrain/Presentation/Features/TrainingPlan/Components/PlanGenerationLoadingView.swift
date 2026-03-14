import SwiftUI

struct PlanGenerationLoadingView: View {
    @State private var currentStep = 0
    @State private var progress: Double = 0

    private let steps: [(icon: String, text: String)] = [
        ("person.fill", "Analyzing your profile"),
        ("calendar.badge.clock", "Building periodization"),
        ("figure.run", "Generating sessions"),
        ("fork.knife", "Preparing nutrition plan")
    ]

    private let stepDuration: TimeInterval = 1.2

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Theme.Colors.secondaryLabel.opacity(0.12), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.Colors.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.accentColor)
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
            }
            .animation(.easeInOut(duration: 0.4), value: currentStep)

            // Step text
            Text(steps[currentStep].text)
                .font(.headline)
                .foregroundStyle(Theme.Colors.label)
                .id("text-\(currentStep)")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.35), value: currentStep)

            // Step dots
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Theme.Colors.accentColor : Theme.Colors.secondaryLabel.opacity(0.2))
                        .frame(width: index == currentStep ? 8 : 6, height: index == currentStep ? 8 : 6)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await runSteps()
        }
    }

    private func runSteps() async {
        for step in 0..<steps.count {
            withAnimation {
                currentStep = step
            }
            let targetProgress = Double(step + 1) / Double(steps.count)
            // Animate progress over stepDuration
            let tickCount = 20
            let tickInterval = stepDuration / Double(tickCount)
            let startProgress = progress
            for tick in 1...tickCount {
                try? await Task.sleep(for: .milliseconds(Int(tickInterval * 1000)))
                let fraction = Double(tick) / Double(tickCount)
                withAnimation(.linear(duration: tickInterval)) {
                    progress = startProgress + (targetProgress - startProgress) * fraction
                }
            }
        }
        // Hold at end, loop back
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation {
            currentStep = 0
            progress = 0
        }
        await runSteps()
    }
}
