import SwiftUI

struct PostRaceResultStep: View {
    @Bindable var viewModel: PostRaceWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            raceInfoHeader
            finishTimeSection
            positionSection
            linkedRunSection
        }
    }

    // MARK: - Race Info Header

    private var raceInfoHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(viewModel.raceName)
                .font(.title2.bold())
            Text("\(String(format: "%.0f", viewModel.raceDistanceKm)) km")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Finish Time

    private var finishTimeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Finish Time")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                LabeledIntStepper(
                    label: "Hours",
                    value: $viewModel.finishTimeHours,
                    range: 0...100,
                    unit: "h"
                )
                LabeledIntStepper(
                    label: "Min",
                    value: $viewModel.finishTimeMinutes,
                    range: 0...59,
                    unit: "m"
                )
                LabeledIntStepper(
                    label: "Sec",
                    value: $viewModel.finishTimeSeconds,
                    range: 0...59,
                    unit: "s"
                )
            }
        }
        .cardStyle()
    }

    // MARK: - Position

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Finish Position (Optional)")
                .font(.headline)

            HStack {
                Text("Position")
                    .font(.subheadline)
                Spacer()
                TextField("e.g. 42", value: $viewModel.actualPosition, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Finish position")
                    .accessibilityHint("Enter your overall finish position")
            }
        }
        .cardStyle()
    }

    // MARK: - Linked Run

    private var linkedRunSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Link to Recorded Run (Optional)")
                .font(.headline)

            if viewModel.recentRuns.isEmpty {
                Text("No recent runs found near race date")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(nearbyRuns) { run in
                    runRow(run)
                }
            }
        }
        .cardStyle()
    }

    private var nearbyRuns: [CompletedRun] {
        let calendar = Calendar.current
        return viewModel.recentRuns.filter { run in
            let daysDiff = abs(calendar.dateComponents([.day], from: run.date, to: viewModel.raceDate).day ?? 999)
            return daysDiff <= 3
        }
    }

    private func runRow(_ run: CompletedRun) -> some View {
        Button {
            if viewModel.selectedRunId == run.id {
                viewModel.selectedRunId = nil
            } else {
                viewModel.selectedRunId = run.id
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                    Text("\(String(format: "%.1f", run.distanceKm)) km")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                Spacer()
                if viewModel.selectedRunId == run.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.primary)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .accessibilityHidden(true)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(
                        viewModel.selectedRunId == run.id
                            ? Theme.Colors.primary.opacity(0.1)
                            : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Run on \(run.date.formatted(date: .abbreviated, time: .shortened)), \(String(format: "%.1f", run.distanceKm)) kilometers")
        .accessibilityAddTraits(viewModel.selectedRunId == run.id ? .isSelected : [])
    }
}
