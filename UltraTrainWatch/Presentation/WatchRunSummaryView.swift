import SwiftUI

struct WatchRunSummaryView: View {
    let viewModel: WatchRunViewModel
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)

                Text("Run Complete")
                    .font(.headline)

                summaryGrid

                Button(action: onDone) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            }
            .padding(.horizontal, 4)
        }
    }

    private var summaryGrid: some View {
        VStack(spacing: 8) {
            summaryRow(icon: "figure.run", label: "Distance", value: "\(viewModel.formattedDistance) km")
            summaryRow(icon: "clock", label: "Time", value: viewModel.formattedTime)
            summaryRow(icon: "speedometer", label: "Pace", value: "\(viewModel.currentPace) /km")
            summaryRow(icon: "mountain.2.fill", label: "Elevation", value: viewModel.formattedElevation)

            if let hr = viewModel.currentHeartRate {
                summaryRow(icon: "heart.fill", label: "Avg HR", value: "\(hr) bpm")
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.green)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
