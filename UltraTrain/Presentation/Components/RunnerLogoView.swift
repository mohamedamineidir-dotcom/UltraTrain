import SwiftUI

struct RunnerLogoView: View {
    let size: CGFloat
    @State private var shimmerOffset: CGFloat = -0.3

    private var lineWidth: CGFloat { size * 0.072 }
    private var headSize: CGFloat { size * 0.125 }

    var body: some View {
        ZStack {
            // Soft blue glow
            runnerLayer(Color(red: 0.45, green: 0.55, blue: 0.85).opacity(0.35))
                .blur(radius: size * 0.09)

            // Main metallic fill
            runnerLayer(metallicGradient)

            // Animated shimmer sweep
            runnerLayer(Color.white.opacity(0.5))
                .mask(shimmerBand)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.8)
                .repeatForever(autoreverses: false)
                .delay(1.0)
            ) {
                shimmerOffset = 1.3
            }
        }
    }

    // MARK: - Gradients

    private var metallicGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.48, green: 0.56, blue: 0.76), location: 0.00),
                .init(color: Color(red: 0.80, green: 0.86, blue: 0.97), location: 0.28),
                .init(color: Color(red: 0.55, green: 0.64, blue: 0.82), location: 0.48),
                .init(color: Color(red: 0.86, green: 0.91, blue: 1.00), location: 0.70),
                .init(color: Color(red: 0.40, green: 0.48, blue: 0.70), location: 1.00),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shimmerBand: some View {
        LinearGradient(
            colors: [.clear, .white, .clear],
            startPoint: UnitPoint(x: shimmerOffset - 0.25, y: shimmerOffset - 0.25),
            endPoint: UnitPoint(x: shimmerOffset + 0.05, y: shimmerOffset + 0.05)
        )
    }

    // MARK: - Runner Layer

    @ViewBuilder
    private func runnerLayer<S: ShapeStyle>(_ style: S) -> some View {
        ZStack {
            Circle()
                .fill(style)
                .frame(width: headSize, height: headSize)
                .position(x: size * 0.70, y: size * 0.12)

            RunnerBodyShape()
                .stroke(style, style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                ))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Runner Body Shape

struct RunnerBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // U-body: back arm tip → left side → bottom curve → right side → front arm tip
        path.move(to: CGPoint(x: w * 0.18, y: h * 0.11))
        path.addCurve(
            to: CGPoint(x: w * 0.23, y: h * 0.53),
            control1: CGPoint(x: w * 0.11, y: h * 0.27),
            control2: CGPoint(x: w * 0.17, y: h * 0.43)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.54, y: h * 0.49),
            control1: CGPoint(x: w * 0.29, y: h * 0.65),
            control2: CGPoint(x: w * 0.44, y: h * 0.63)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.22),
            control1: CGPoint(x: w * 0.61, y: h * 0.38),
            control2: CGPoint(x: w * 0.70, y: h * 0.28)
        )

        // Back leg
        path.move(to: CGPoint(x: w * 0.27, y: h * 0.54))
        path.addCurve(
            to: CGPoint(x: w * 0.10, y: h * 0.88),
            control1: CGPoint(x: w * 0.20, y: h * 0.67),
            control2: CGPoint(x: w * 0.12, y: h * 0.79)
        )

        // Front leg with knee bend
        path.move(to: CGPoint(x: w * 0.45, y: h * 0.56))
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.72),
            control1: CGPoint(x: w * 0.47, y: h * 0.61),
            control2: CGPoint(x: w * 0.50, y: h * 0.68)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.88),
            control1: CGPoint(x: w * 0.54, y: h * 0.76),
            control2: CGPoint(x: w * 0.59, y: h * 0.83)
        )

        return path
    }
}
