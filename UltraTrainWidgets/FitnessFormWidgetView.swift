import SwiftUI
import WidgetKit

struct FitnessFormWidgetView: View {
    let entry: FitnessFormEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let fitness = entry.fitness {
            switch family {
            case .accessoryCircular:
                circularView(fitness)
            case .accessoryRectangular:
                rectangularView(fitness)
            default:
                smallView(fitness)
            }
        } else {
            emptyView
        }
    }

    // MARK: - Circular

    private func circularView(_ fitness: WidgetFitnessData) -> some View {
        let clamped = max(-50, min(50, fitness.form))
        let normalized = (clamped + 50) / 100
        return Gauge(value: normalized) {
            Image(systemName: "waveform.path.ecg")
        } currentValueLabel: {
            Text(formattedForm(fitness.form))
                .font(.system(.caption2, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
    }

    // MARK: - Rectangular

    private func rectangularView(_ fitness: WidgetFitnessData) -> some View {
        HStack(spacing: 6) {
            Text(formattedForm(fitness.form))
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(formColor(fitness.form))

            VStack(alignment: .leading, spacing: 1) {
                Text(formStatus(fitness.form))
                    .font(.headline)
                Text("Fitness \(Int(fitness.fitness)) | Fatigue \(Int(fitness.fatigue))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Small

    private func smallView(_ fitness: WidgetFitnessData) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Form")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text(formattedForm(fitness.form))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(formColor(fitness.form))

            Text(formStatus(fitness.form))
                .font(.caption.bold())
                .foregroundStyle(formColor(fitness.form))

            Spacer(minLength: 0)

            HStack {
                statLabel("CTL", value: Int(fitness.fitness))
                Spacer()
                statLabel("ATL", value: Int(fitness.fatigue))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Fitness Data")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func statLabel(_ label: String, value: Int) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
