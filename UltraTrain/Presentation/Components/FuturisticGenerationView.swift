import SwiftUI

struct FuturisticGenerationView: View {
    let steps: [(icon: String, title: String, subtitle: String)]
    let accentColor: Color
    let stepDuration: TimeInterval
    let loops: Bool
    let onComplete: (() -> Void)?

    @State private var currentStep = 0
    @State private var progress: Double = 0
    @State private var ringRotation: Double = 0
    @State private var glowPulse = false
    @State private var meshPhase = false

    init(
        steps: [(icon: String, title: String, subtitle: String)],
        accentColor: Color = Theme.Colors.accentColor,
        stepDuration: TimeInterval = 2.0,
        loops: Bool = true,
        onComplete: (() -> Void)? = nil
    ) {
        self.steps = steps
        self.accentColor = accentColor
        self.stepDuration = stepDuration
        self.loops = loops
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            backgroundLayers
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                ringSection
                stepInfo
                timeline
                Spacer()
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
            // Base: deep dark gradient (not pure black)
            Theme.Colors.futuristicBgDark
                .ignoresSafeArea()

            // Ambient gradient orbs that drift slowly
            ambientOrbs

            // Scanlines for the holographic feel
            scanlines

            // Floating particles
            FloatingParticlesView(color: accentColor)
        }
    }

    private var ambientOrbs: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height * 0.42

            // Primary orb (centered on the ring area)
            RadialGradient(
                colors: [accentColor.opacity(0.07), Color.clear],
                center: UnitPoint(
                    x: (cx + (meshPhase ? 20 : -20)) / geo.size.width,
                    y: (cy + (meshPhase ? -15 : 15)) / geo.size.height
                ),
                startRadius: 10,
                endRadius: 220
            )

            // Secondary orb (upper-right, subtle)
            RadialGradient(
                colors: [accentColor.opacity(0.035), Color.clear],
                center: UnitPoint(
                    x: (geo.size.width * 0.75 + (meshPhase ? -25 : 25)) / geo.size.width,
                    y: (geo.size.height * 0.2 + (meshPhase ? 20 : -20)) / geo.size.height
                ),
                startRadius: 5,
                endRadius: 160
            )

            // Tertiary orb (lower-left, warm tint)
            RadialGradient(
                colors: [Color.purple.opacity(0.025), Color.clear],
                center: UnitPoint(
                    x: (geo.size.width * 0.2 + (meshPhase ? 15 : -15)) / geo.size.width,
                    y: (geo.size.height * 0.75 + (meshPhase ? -10 : 10)) / geo.size.height
                ),
                startRadius: 5,
                endRadius: 140
            )
        }
        .ignoresSafeArea()
    }

    private var scanlines: some View {
        Canvas { context, size in
            for y in stride(from: CGFloat(0), through: size.height, by: 50) {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 0.5)
                context.fill(Path(rect), with: .color(.white.opacity(0.015)))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Ring

    private var ringSection: some View {
        ZStack {
            ScannerRingOverlay(color: accentColor, diameter: 170)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 4)
                .frame(width: 140, height: 140)

            // Spinning comet tail
            Circle()
                .trim(from: 0, to: 0.35)
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor.opacity(0),
                            accentColor.opacity(0.3),
                            accentColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(ringRotation))

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(-90))

            // Glass center
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(accentColor.opacity(0.06)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                .frame(width: 90, height: 90)

            // Icon (no shadow)
            Image(systemName: steps[currentStep].icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(accentColor)
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
                .foregroundStyle(accentColor.opacity(0.6))

            Text(steps[currentStep].title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(steps[currentStep].subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.45))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.3))
                .padding(.top, Theme.Spacing.xs)
        }
        .id("step-\(currentStep)")
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.4), value: currentStep)
    }

    // MARK: - Timeline

    private var timeline: some View {
        StepTimelineView(
            stepCount: steps.count,
            currentStep: currentStep,
            color: accentColor
        )
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.pulseGlow) {
            glowPulse = true
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
        if loops {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation {
                currentStep = 0
                progress = 0
            }
            await runSteps()
        } else {
            onComplete?()
        }
    }
}
