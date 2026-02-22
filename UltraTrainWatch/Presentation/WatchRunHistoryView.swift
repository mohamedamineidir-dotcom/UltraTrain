import SwiftUI

struct WatchRunHistoryView: View {
    let runs: [WatchRunHistoryData]

    var body: some View {
        List {
            if runs.isEmpty {
                Text("No runs yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(runs) { run in
                    runRow(run)
                }
            }
        }
        .navigationTitle("History")
    }

    private func runRow(_ run: WatchRunHistoryData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(run.date, style: .date)
                .font(.caption.bold())
            HStack(spacing: 8) {
                Text(String(format: "%.1f km", run.distanceKm))
                Text(WatchRunCalculator.formatPace(run.averagePaceSecondsPerKm) + " /km")
                if let hr = run.averageHeartRate {
                    Text("\(hr) bpm")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
