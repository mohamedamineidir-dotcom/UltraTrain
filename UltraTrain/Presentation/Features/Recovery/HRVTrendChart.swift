import SwiftUI
import Charts

struct HRVTrendChart: View {
    let readings: [HRVReading]

    private var movingAverageData: [(date: Date, average: Double)] {
        guard readings.count >= 7 else { return [] }
        let sorted = readings.sorted { $0.date < $1.date }
        var result: [(date: Date, average: Double)] = []
        for i in 6..<sorted.count {
            let window = sorted[(i - 6)...i]
            let avg = window.map(\.sdnnMs).reduce(0, +) / 7
            result.append((date: sorted[i].date, average: avg))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("HRV Trend")
                .font(.headline)
            Chart {
                ForEach(readings) { reading in
                    PointMark(
                        x: .value("Date", reading.date, unit: .day),
                        y: .value("SDNN", reading.sdnnMs)
                    )
                    .foregroundStyle(Theme.Colors.success.opacity(0.5))
                    .symbolSize(20)
                }
                ForEach(Array(movingAverageData.enumerated()), id: \.offset) { _, item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("7d Avg", item.average)
                    )
                    .foregroundStyle(Theme.Colors.success)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxisLabel("SDNN (ms)")
            .frame(height: 180)
        }
        .cardStyle()
    }
}
