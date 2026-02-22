import SwiftUI

struct MorningReadinessView: View {
    @State private var viewModel: MorningReadinessViewModel
    @State private var showingCheckInSheet = false

    private let morningCheckInRepository: (any MorningCheckInRepository)?
    private let recoveryRepository: any RecoveryRepository

    init(
        healthKitService: any HealthKitServiceProtocol,
        recoveryRepository: any RecoveryRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        fitnessRepository: any FitnessRepository,
        morningCheckInRepository: (any MorningCheckInRepository)? = nil
    ) {
        self.morningCheckInRepository = morningCheckInRepository
        self.recoveryRepository = recoveryRepository
        _viewModel = State(initialValue: MorningReadinessViewModel(
            healthKitService: healthKitService,
            recoveryRepository: recoveryRepository,
            fitnessCalculator: fitnessCalculator,
            fitnessRepository: fitnessRepository,
            morningCheckInRepository: morningCheckInRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, Theme.Spacing.xl)
                } else if let readiness = viewModel.readinessScore {
                    checkInButton
                    readinessGaugeSection(readiness)
                    if let checkIn = viewModel.morningCheckIn {
                        checkInSummary(checkIn)
                    }
                    componentBreakdown(readiness)
                    if !viewModel.recommendations.isEmpty {
                        RecoveryRecommendationsCard(recommendations: viewModel.recommendations)
                    }
                    SessionSuggestionCard(recommendation: readiness.sessionRecommendation)
                        .padding(.horizontal, Theme.Spacing.md)
                    if let trend = viewModel.hrvTrend {
                        hrvSection(trend)
                    }
                    if let sleep = viewModel.sleepEntry {
                        sleepSummary(sleep)
                    }
                    if !viewModel.recoveryHistory.isEmpty {
                        RecoveryTrendChart(snapshots: viewModel.recoveryHistory)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                    if !viewModel.hrvReadings.isEmpty {
                        HRVTrendChart(readings: viewModel.hrvReadings)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                    if let repo = morningCheckInRepository {
                        NavigationLink {
                            RecoveryHistoryView(
                                recoveryRepository: recoveryRepository,
                                morningCheckInRepository: repo
                            )
                        } label: {
                            Label("View Recovery History", systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                        .fill(Theme.Colors.secondaryBackground)
                                )
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                } else {
                    ContentUnavailableView(
                        "No Recovery Data",
                        systemImage: "heart.text.clipboard",
                        description: Text("Recovery data will appear after sleep tracking is available.")
                    )
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .navigationTitle("Morning Readiness")
        .task { await viewModel.load() }
        .sheet(isPresented: $showingCheckInSheet, onDismiss: {
            Task { await viewModel.load() }
        }) {
            if let repo = morningCheckInRepository {
                MorningCheckInSheet(morningCheckInRepository: repo)
            }
        }
    }

    // MARK: - Check-In

    private var checkInButton: some View {
        Button {
            showingCheckInSheet = true
        } label: {
            Label(
                viewModel.morningCheckIn != nil ? "Edit Check-In" : "Morning Check-In",
                systemImage: viewModel.morningCheckIn != nil ? "checkmark.circle.fill" : "plus.circle"
            )
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary.opacity(0.15))
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .disabled(morningCheckInRepository == nil)
    }

    private func checkInSummary(_ checkIn: MorningCheckIn) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            checkInMetric(emoji: "⚡️", label: "Energy", value: checkIn.perceivedEnergy)
            Divider().frame(height: 30)
            checkInMetric(emoji: "💪", label: "Soreness", value: checkIn.muscleSoreness)
            Divider().frame(height: 30)
            checkInMetric(emoji: "😊", label: "Mood", value: checkIn.mood)
            Divider().frame(height: 30)
            checkInMetric(emoji: "😴", label: "Sleep", value: checkIn.sleepQualitySubjective)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Check-in: Energy \(checkIn.perceivedEnergy), Soreness \(checkIn.muscleSoreness), Mood \(checkIn.mood), Sleep \(checkIn.sleepQualitySubjective)")
    }

    private func checkInMetric(emoji: String, label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(emoji)
                .font(.title3)
            Text("\(value)/5")
                .font(.caption.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Sections

    private func readinessGaugeSection(_ readiness: ReadinessScore) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            RecoveryScoreGauge(score: readiness.overallScore, status: recoveryStatus(from: readiness.status))
                .frame(width: 160, height: 160)
            ReadinessBadge(score: readiness.overallScore, status: readiness.status)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private func componentBreakdown(_ readiness: ReadinessScore) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Components")
                .font(.headline)
            componentBar(label: "Recovery", score: readiness.recoveryComponent, color: Theme.Colors.primary)
            if readiness.hrvComponent > 0 {
                componentBar(label: "HRV", score: readiness.hrvComponent, color: Theme.Colors.success)
            }
            componentBar(label: "Training Load", score: readiness.trainingLoadComponent, color: Theme.Colors.warning)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func componentBar(label: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text("\(score)").font(.caption.bold().monospacedDigit())
            }
            .foregroundStyle(Theme.Colors.secondaryLabel)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(score) out of 100")
    }

    private func hrvSection(_ trend: HRVAnalyzer.HRVTrend) -> some View {
        HRVIndicator(
            currentHRV: trend.currentHRV,
            trend: trend.trend,
            sevenDayAverage: trend.sevenDayAverage
        )
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func recoveryStatus(from readiness: ReadinessStatus) -> RecoveryStatus {
        switch readiness {
        case .primed: .excellent
        case .ready: .good
        case .moderate: .moderate
        case .fatigued: .poor
        case .needsRest: .critical
        }
    }

    private func sleepSummary(_ sleep: SleepEntry) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(spacing: 2) {
                Text("Sleep")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(String(format: "%.1fh", sleep.totalSleepDuration / 3600))
                    .font(.subheadline.bold().monospacedDigit())
            }
            Divider().frame(height: 30)
            VStack(spacing: 2) {
                Text("Deep")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(String(format: "%.1fh", sleep.deepSleepDuration / 3600))
                    .font(.subheadline.bold().monospacedDigit())
            }
            Divider().frame(height: 30)
            VStack(spacing: 2) {
                Text("Efficiency")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("\(Int(sleep.sleepEfficiency * 100))%")
                    .font(.subheadline.bold().monospacedDigit())
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep: \(String(format: "%.1f", sleep.totalSleepDuration / 3600)) hours, Deep: \(String(format: "%.1f", sleep.deepSleepDuration / 3600)) hours, Efficiency: \(Int(sleep.sleepEfficiency * 100)) percent")
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.secondaryBackground)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }
}
