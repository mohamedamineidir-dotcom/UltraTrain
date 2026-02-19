import Charts
import SwiftUI
import WidgetKit

struct FitnessTrendWidgetView: View {
    let entry: FitnessTrendEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let fitness = entry.fitness {
            switch family {
            case .systemSmall:
                smallView(fitness)
            default:
                mediumView(fitness)
            }
        } else {
            emptyView
        }
    }

    // MARK: - Small

    private func smallView(_ fitness: WidgetFitnessData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Trend")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text(formattedForm(fitness.form))
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(formColor(fitness.form))

            sparkline(fitness.trend)
                .frame(height: 40)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium

    private func mediumView(_ fitness: WidgetFitnessData) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Fitness Trend")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }

                sparkline(fitness.trend)
                    .frame(height: 60)

                Spacer(minLength: 0)
            }

            VStack(alignment: .trailing, spacing: 6) {
                formBadge(fitness.form)

                statRow("CTL", value: Int(fitness.fitness), color: .blue)
                statRow("ATL", value: Int(fitness.fatigue), color: .red)
                statRow("TSB", value: Int(fitness.form), color: formColor(fitness.form))

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Sparkline

    private func sparkline(_ points: [WidgetFitnessPoint]) -> some View {
        Chart(points, id: \.date) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Form", point.form)
            )
            .foregroundStyle(formColor(points.last?.form ?? 0))
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Form", point.form)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [formColor(points.last?.form ?? 0).opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Fitness Data")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formBadge(_ form: Double) -> some View {
        Text(formStatus(form))
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(formColor(form).opacity(0.2))
            .foregroundStyle(formColor(form))
            .clipShape(Capsule())
    }

    private func statRow(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }

    private func formattedForm(_ form: Double) -> String {
        let rounded = Int(form)
        return rounded >= 0 ? "+\(rounded)" : "\(rounded)"
    }

    private func formColor(_ form: Double) -> Color {
        if form > 10 { return .green }
        if form > -5 { return .orange }
        return .red
    }

    private func formStatus(_ form: Double) -> String {
        if form > 10 { return "Fresh" }
        if form > -5 { return "Neutral" }
        return "Fatigued"
    }
}
