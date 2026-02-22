import SwiftUI

struct IntervalPhaseBanner: View {
    let transition: IntervalPhaseTransition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(transition.message)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                if let num = transition.intervalNumber, let total = transition.totalIntervals {
                    Text("Interval \(num) of \(total)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding()
        .background(bannerColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var iconName: String {
        switch transition.toPhase {
        case .warmUp: return "flame.fill"
        case .work: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .coolDown: return "snowflake"
        }
    }

    private var bannerColor: Color {
        switch transition.toPhase {
        case .warmUp: return .orange
        case .work: return .red
        case .recovery: return .blue
        case .coolDown: return .green
        }
    }
}
