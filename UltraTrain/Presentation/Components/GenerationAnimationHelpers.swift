import SwiftUI

// MARK: - Floating Particles

struct FloatingParticlesView: View {
    let color: Color

    @State private var phase = false

    private let seeds: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double, dx: CGFloat, dy: CGFloat)] = [
        (0.15, 0.20, 2, 0.12, 10, -8),
        (0.75, 0.15, 3, 0.18, -12, 6),
        (0.90, 0.40, 2, 0.10, -8, 10),
        (0.10, 0.60, 4, 0.14, 14, -6),
        (0.80, 0.70, 2, 0.20, -10, -12),
        (0.30, 0.85, 3, 0.12, 8, 8),
        (0.55, 0.10, 2, 0.16, -6, 14),
        (0.20, 0.45, 3, 0.10, 12, -10),
        (0.65, 0.55, 2, 0.14, -14, 6),
        (0.40, 0.75, 4, 0.18, 6, -14)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<seeds.count, id: \.self) { i in
                let s = seeds[i]
                Circle()
                    .fill(color)
                    .frame(width: s.size, height: s.size)
                    .opacity(s.opacity)
                    .blur(radius: 0.5)
                    .position(
                        x: geo.size.width * s.x + (phase ? s.dx : -s.dx),
                        y: geo.size.height * s.y + (phase ? s.dy : -s.dy)
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }
}

// MARK: - Scanner Ring Overlay

struct ScannerRingOverlay: View {
    let color: Color
    let diameter: CGFloat

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            tickMarks
            orbitDots
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    private var tickMarks: some View {
        ForEach(0..<36, id: \.self) { i in
            let isMajor = i % 9 == 0
            Capsule()
                .fill(color.opacity(isMajor ? 0.25 : 0.07))
                .frame(width: isMajor ? 1.5 : 0.8, height: isMajor ? 10 : 5)
                .offset(y: -(diameter / 2 + 8))
                .rotationEffect(.degrees(Double(i) * 10))
        }
    }

    private var orbitDots: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 3.5, height: 3.5)
                .shadow(color: color.opacity(0.4), radius: 4)
                .offset(y: -(diameter / 2 + 4))
                .rotationEffect(.degrees(rotation))

            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 2.5, height: 2.5)
                .offset(y: -(diameter / 2 + 18))
                .rotationEffect(.degrees(-rotation * 0.5))
        }
    }
}

// MARK: - Step Timeline

struct StepTimelineView: View {
    let stepCount: Int
    let currentStep: Int
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<stepCount, id: \.self) { index in
                dot(for: index)
                if index < stepCount - 1 {
                    line(after: index)
                }
            }
        }
        .frame(width: 180)
    }

    private func dot(for index: Int) -> some View {
        ZStack {
            if index == currentStep {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 1)
                    .frame(width: 18, height: 18)
            }

            if index <= currentStep {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 14, height: 14)
            }

            Circle()
                .fill(index <= currentStep ? color : Color.white.opacity(0.15))
                .frame(width: 6, height: 6)
                .shadow(
                    color: index == currentStep ? color.opacity(0.5) : .clear,
                    radius: 4
                )
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private func line(after index: Int) -> some View {
        Rectangle()
            .fill(index < currentStep ? color.opacity(0.3) : Color.white.opacity(0.06))
            .frame(height: 1)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
