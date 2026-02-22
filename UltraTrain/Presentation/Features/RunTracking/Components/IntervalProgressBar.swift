import SwiftUI

struct IntervalProgressBar: View {
    let state: IntervalWorkoutState

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                phaseLabel
                Spacer()
                remainingLabel
            }
            .font(.caption.weight(.semibold))

            ProgressView(value: phaseProgress)
                .tint(phaseColor)

            HStack {
                Text(state.currentPhaseType.displayName.uppercased())
                    .font(.caption2)
                    .foregroundStyle(phaseColor)
                Spacer()
                Text("\(state.completedPhases + 1)/\(state.totalPhases)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Computed

    private var phaseLabel: some View {
        Group {
            if state.currentPhaseType == .work {
                Text("Interval \(state.currentRepeat)/\(state.totalRepeats)")
            } else {
                Text(state.currentPhaseType.displayName)
            }
        }
        .foregroundStyle(phaseColor)
    }

    private var remainingLabel: some View {
        Group {
            if let remaining = state.phaseRemainingTime {
                Text(formatRemaining(remaining))
            } else if let remaining = state.phaseRemainingDistance {
                Text(String(format: "%.2f km", remaining))
            } else {
                Text("")
            }
        }
        .foregroundStyle(.primary)
    }

    private var phaseColor: Color {
        switch state.currentPhaseType {
        case .warmUp: return .orange
        case .work: return .red
        case .recovery: return .blue
        case .coolDown: return .green
        }
    }

    private var phaseProgress: Double {
        if let remaining = state.phaseRemainingTime {
            let total = state.phaseElapsedTime + remaining
            guard total > 0 else { return 0 }
            return state.phaseElapsedTime / total
        }
        if let remaining = state.phaseRemainingDistance {
            let total = state.phaseElapsedDistance + remaining
            guard total > 0 else { return 0 }
            return state.phaseElapsedDistance / total
        }
        return 0
    }

    private func formatRemaining(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let min = total / 60
        let sec = total % 60
        return String(format: "%d:%02d", min, sec)
    }
}
