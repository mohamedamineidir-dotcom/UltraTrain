import SwiftUI

struct IntervalWorkoutPreviewView: View {
    @Bindable var viewModel: IntervalWorkoutPreviewViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsCard
                phaseTimeline
            }
            .padding()
        }
        .navigationTitle(viewModel.workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 16) {
            statItem(title: "Intervals", value: "\(viewModel.workout.intervalCount)")
            Divider().frame(height: 40)
            statItem(title: "Duration", value: viewModel.formattedDuration)
            Divider().frame(height: 40)
            statItem(title: "W:R Ratio", value: viewModel.formattedWorkToRest)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Phase Timeline

    private var phaseTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.flattenedPhases.enumerated()), id: \.offset) { index, entry in
                HStack(spacing: 12) {
                    Circle()
                        .fill(phaseColor(entry.phase.phaseType))
                        .frame(width: 12, height: 12)

                    Text(entry.phase.phaseType.displayName)
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Text(entry.phase.trigger.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.phase.targetIntensity.rawValue.capitalized)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(phaseColor(entry.phase.phaseType).opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.vertical, 8)

                if index < viewModel.flattenedPhases.count - 1 {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2, height: 16)
                        .padding(.leading, 5)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func phaseColor(_ type: IntervalPhaseType) -> Color {
        switch type {
        case .warmUp: return .orange
        case .work: return .red
        case .recovery: return .blue
        case .coolDown: return .green
        }
    }
}
