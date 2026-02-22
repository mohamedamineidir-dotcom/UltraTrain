import SwiftUI
import Charts

struct RecoveryHistoryView: View {
    @State private var viewModel: RecoveryHistoryViewModel

    init(
        recoveryRepository: any RecoveryRepository,
        morningCheckInRepository: any MorningCheckInRepository
    ) {
        _viewModel = State(initialValue: RecoveryHistoryViewModel(
            recoveryRepository: recoveryRepository,
            morningCheckInRepository: morningCheckInRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Theme.Spacing.xl)
                } else if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text("Recovery history will appear after a few days of tracking.")
                    )
                } else {
                    trendChart
                    dayList
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .navigationTitle("Recovery History")
        .task { await viewModel.load() }
    }

    // MARK: - Trend Chart

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("30-Day Trend")
                .font(.headline)

            Chart {
                ForEach(viewModel.entries.reversed()) { entry in
                    if let score = entry.recoveryScore {
                        LineMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Recovery", score)
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100])
            }
            .frame(height: 180)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Day List

    private var dayList: some View {
        LazyVStack(spacing: Theme.Spacing.sm) {
            ForEach(viewModel.entries) { entry in
                dayRow(entry)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func dayRow(_ entry: RecoveryHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.subheadline.bold())
                Spacer()
                if let score = entry.recoveryScore {
                    scoreLabel(score)
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                if let readiness = entry.readinessScore {
                    metricPill(label: "Readiness", value: "\(readiness)")
                }
                if let checkIn = entry.checkIn {
                    metricPill(label: "Energy", value: "\(checkIn.perceivedEnergy)/5")
                    metricPill(label: "Soreness", value: "\(checkIn.muscleSoreness)/5")
                    metricPill(label: "Mood", value: "\(checkIn.mood)/5")
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .accessibilityElement(children: .combine)
    }

    private func scoreLabel(_ score: Int) -> some View {
        Text("\(score)")
            .font(.headline.monospacedDigit())
            .foregroundStyle(scoreColor(score))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(scoreColor(score).opacity(0.15))
            )
    }

    private func metricPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.caption.bold().monospacedDigit())
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: Theme.Colors.success
        case 60..<80: Theme.Colors.primary
        case 40..<60: Theme.Colors.warning
        default: Theme.Colors.danger
        }
    }
}
