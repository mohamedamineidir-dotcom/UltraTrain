import SwiftUI

struct SessionCompletionLoadingView: View {
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var progress: Double = 0
    @State private var ringRotation: Double = 0
    @State private var checkScale: CGFloat = 0
    @State private var meshPhase = false
    @State private var finished = false

    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("checkmark.circle", "Saving your session", "Recording stats & performance data"),
        ("chart.line.uptrend.xyaxis", "Updating training load", "Recalculating fitness & fatigue"),
        ("calendar.badge.checkmark", "Adjusting your plan", "Optimizing upcoming sessions")
    ]

    private let stepDuration: TimeInterval = 1.4
    private let accent = Theme.Colors.success

    var body: some View {
        ZStack {
            backgroundLayers

            if finished {
                completionBurst
            } else {
                activeContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .task { await runSteps() }
        .onAppear { startAnimations() }
    }

    // MARK: - Background

    private var backgroundLayers: some View {
        ZStack {
            Theme.Colors.futuristicBgDark
                .ignoresSafeArea()

            ambientOrbs

            Canvas { context, size in
                for y in stride(from: CGFloat(0), through: size.height, by: 50) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 0.5)
                    context.fill(Path(rect), with: .color(.white.opacity(0.015)))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            FloatingParticlesView(color: accent)
        }
    }

    private var ambientOrbs: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [accent.opacity(0.06), Color.clear],
                center: UnitPoint(
                    x: (geo.size.width * 0.5 + (meshPhase ? 15 : -15)) / geo.size.width,
                    y: (geo.size.height * 0.38 + (meshPhase ? -10 : 10)) / geo.size.height
                ),
                startRadius: 10,
                endRadius: 200
            )

            RadialGradient(
                colors: [Color.mint.opacity(0.03), Color.clear],
                center: UnitPoint(
                    x: (geo.size.width * 0.7 + (meshPhase ? -20 : 20)) / geo.size.width,
                    y: (geo.size.height * 0.65 + (meshPhase ? 12 : -12)) / geo.size.height
                ),
                startRadius: 5,
                endRadius: 130
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Active Content

    private var activeContent: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ringSection
            stepInfo
            stepTimeline
            Spacer()
        }
    }

    // MARK: - Ring

    private var ringSection: some View {
        ZStack {
            ScannerRingOverlay(color: accent, diameter: 150)

            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 3.5)
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    AngularGradient(
                        colors: [accent.opacity(0), accent.opacity(0.3), accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 108, height: 108)
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(accent.opacity(0.06)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                .frame(width: 76, height: 76)

            Image(systemName: steps[currentStep].icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(accent)
                .id(currentStep)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.5).combined(with: .opacity),
                    removal: .scale(scale: 1.3).combined(with: .opacity)
                ))
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }

    // MARK: - Step Info

    private var stepInfo: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("STEP \(currentStep + 1) OF \(steps.count)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .kerning(Theme.LetterSpacing.tracked)
                .foregroundStyle(accent.opacity(0.6))

            Text(steps[currentStep].title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(steps[currentStep].subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .id("step-\(currentStep)")
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.4), value: currentStep)
    }

    // MARK: - Timeline

    private var stepTimeline: some View {
        StepTimelineView(
            stepCount: steps.count,
            currentStep: currentStep,
            color: accent
        )
    }

    // MARK: - Completion Burst

    private var completionBurst: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .scaleEffect(checkScale)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(accent)
                    .scaleEffect(checkScale)
            }

            Text("Session Complete!")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .opacity(checkScale > 0.5 ? 1 : 0)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            meshPhase = true
        }
    }

    private func runSteps() async {
        for step in 0..<steps.count {
            withAnimation { currentStep = step }
            let target = Double(step + 1) / Double(steps.count)
            let start = progress
            let ticks = 20
            let interval = stepDuration / Double(ticks)
            for tick in 1...ticks {
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                let frac = Double(tick) / Double(ticks)
                withAnimation(.linear(duration: interval)) {
                    progress = start + (target - start) * frac
                }
            }
        }

        // Show completion burst
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            finished = true
            checkScale = 1.0
        }

        try? await Task.sleep(for: .seconds(1.0))
        onComplete()
    }
}
