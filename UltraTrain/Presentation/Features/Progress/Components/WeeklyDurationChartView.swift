import SwiftUI
import Charts

struct WeeklyDurationChartView: View {
    let weeklyVolumes: [WeeklyVolume]
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Weekly Duration")
                .font(.headline)

            chart
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary)
    }

    private var chartSummary: String {
        let totalHours = weeklyVolumes.reduce(0.0) { $0 + $1.duration } / 3600
        guard let latest = weeklyVolumes.last else { return "Weekly duration chart, no data" }
        let latestHours = latest.duration / 3600
        return "Weekly duration chart. \(weeklyVolumes.count) weeks. Latest week \(String(format: "%.1f", latestHours)) hours. Total \(String(format: "%.0f", totalHours)) hours."
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(weeklyVolumes) { week in
                BarMark(
                    x: .value("Week", week.weekStartDate, unit: .weekOfYear),
                    y: .value("Duration", week.duration / 3600)
                )
                .foregroundStyle(Theme.Colors.zone3.gradient)
                .cornerRadius(4)
            }

            if let selectedDate, let week = nearestWeek(to: selectedDate) {
                RuleMark(x: .value("Selected", week.weekStartDate, unit: .weekOfYear))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYAxisLabel("hours")
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(String(format: "%.0fh", hours))
                    }
                }
            }
        }
        .frame(height: 180)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    selectedDate = date
                                }
                            }
                            .onEnded { _ in
                                selectedDate = nil
                            }
                    )
            }
        }
        .chartBackground { proxy in
            GeometryReader { geo in
                if let selectedDate, let week = nearestWeek(to: selectedDate) {
                    let plotFrame = geo[proxy.plotFrame!]
                    if let xPos = proxy.position(forX: week.weekStartDate) {
                        ChartAnnotationCard(
                            title: week.weekStartDate.formatted(.dateTime.month(.abbreviated).day()),
                            value: formatDuration(week.duration),
                            subtitle: "\(week.runCount) run\(week.runCount == 1 ? "" : "s")"
                        )
                        .offset(
                            x: annotationX(xPos: xPos, plotWidth: plotFrame.width),
                            y: -8
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func nearestWeek(to date: Date) -> WeeklyVolume? {
        weeklyVolumes.min { abs($0.weekStartDate.timeIntervalSince(date)) < abs($1.weekStartDate.timeIntervalSince(date)) }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    private func annotationX(xPos: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let cardWidth: CGFloat = 110
        return min(max(xPos, cardWidth / 2), plotWidth - cardWidth / 2)
    }
}
