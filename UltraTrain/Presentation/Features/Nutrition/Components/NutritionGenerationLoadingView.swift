import SwiftUI

struct NutritionGenerationLoadingView: View {
    @State private var currentStep = 0
    @State private var progress: Double = 0
    @State private var ringRotation: Double = 0
    @State private var glowPulse = false

    private let accentColor = Theme.Colors.success

    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("figure.run", "Analyzing race profile", "Distance, elevation & expected duration"),
        ("bolt.fill", "Calculating energy needs", "Calories, carbs & fat oxidation rates"),
        ("drop.fill", "Building hydration strategy", "Fluid intake & electrolyte balance"),
        ("fork.knife", "Finalizing nutrition plan", "Products, timing & gut training schedule")
    ]

    private let stepDuration: TimeInterval = 2.0

    var body: some View {
        ZStack {
            backgroundGradient
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .task { await runSteps() }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.pulseGlow) {
                glowPulse = true
            }
        }
    }

    private var backgroundGradient: some View {
        RadialGradient(
            colors: [
                accentColor.opacity(glowPulse ? 0.08 : 0.03),
                Theme.Colors.futuristicBgDark,
                Color.black
            ],
            center: .center,
            startRadius: 20,
            endRadius: 400
        )
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            progressRing
            stepText
            percentageText
            stepIndicator
            Spacer()
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 5)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    AngularGradient(
                        colors: [accentColor.opacity(0), accentColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accentColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))

            Image(systemName: steps[currentStep].icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(accentColor)
                .shadow(color: accentColor.opacity(0.5), radius: 8)
                .id(currentStep)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.5).combined(with: .opacity),
                    removal: .scale(scale: 1.3).combined(with: .opacity)
                ))
        }
        .shadow(color: accentColor.opacity(glowPulse ? 0.3 : 0.1), radius: 20)
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }

    private var stepText: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(steps[currentStep].title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(steps[currentStep].subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .id("step-\(currentStep)")
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.4), value: currentStep)
    }

    private var percentageText: some View {
        Text("\(Int(progress * 100))%")
            .font(.caption.monospacedDigit())
            .foregroundStyle(Color.white.opacity(0.35))
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(capsuleFill(for: index))
                    .frame(width: capsuleWidth(for: index), height: 4)
                    .shadow(
                        color: index == currentStep
                            ? accentColor.opacity(0.5) : .clear,
                        radius: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    private func capsuleFill(for index: Int) -> Color {
        if index <= currentStep { return accentColor }
        return Color.white.opacity(0.15)
    }

    private func capsuleWidth(for index: Int) -> CGFloat {
        if index == currentStep { return 32 }
        if index < currentStep { return 20 }
        return 12
    }

    private func runSteps() async {
        for step in 0..<steps.count {
            withAnimation { currentStep = step }
            let target = Double(step + 1) / Double(steps.count)
            let start = progress
            let ticks = 30
            let interval = stepDuration / Double(ticks)
            for tick in 1...ticks {
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                let frac = Double(tick) / Double(ticks)
                withAnimation(.linear(duration: interval)) {
                    progress = start + (target - start) * frac
                }
            }
        }
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation {
            currentStep = 0
            progress = 0
        }
        await runSteps()
    }
}
