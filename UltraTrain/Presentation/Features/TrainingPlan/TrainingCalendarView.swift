import SwiftUI

struct TrainingCalendarView: View {
    @State private var viewModel: TrainingCalendarViewModel

    init(
        planRepository: any TrainingPlanRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        _viewModel = State(initialValue: TrainingCalendarViewModel(
            planRepository: planRepository,
            runRepository: runRepository,
            athleteRepository: athleteRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if viewModel.isLoading {
                    ProgressView("Loading calendar...")
                } else {
                    TrainingCalendarGridView(
                        displayedMonth: viewModel.displayedMonth,
                        statusForDate: viewModel.dayStatus,
                        phaseForDate: viewModel.phaseForDate,
                        selectedDate: $viewModel.selectedDate,
                        onNavigate: { viewModel.navigateMonth(by: $0) }
                    )

                    TrainingCalendarLegend()

                    weekSummary
                }
            }
            .padding()
        }
        .navigationTitle("Training Calendar")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.selectedDate) { date in
            TrainingCalendarDayDetail(
                date: date,
                phase: viewModel.phaseForDate(date),
                sessions: viewModel.sessionsForDate(date),
                runs: viewModel.runsForDate(date)
            )
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - Week Summary

    @ViewBuilder
    private var weekSummary: some View {
        if let plan = viewModel.plan,
           let currentWeek = plan.weeks.first(where: \.containsToday) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Week \(currentWeek.weekNumber) — \(currentWeek.phase.displayName)")
                    .font(.headline)

                let active = currentWeek.sessions.filter { $0.type != .rest }
                let completed = active.filter(\.isCompleted).count

                HStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sessions")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text("\(completed)/\(active.count)")
                            .font(.title3.bold().monospacedDigit())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Runs This Month")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text("\(runsInDisplayedMonth)")
                            .font(.title3.bold().monospacedDigit())
                    }
                }
            }
            .cardStyle()
        }
    }

    private var runsInDisplayedMonth: Int {
        let calendar = Calendar.current
        return viewModel.completedRuns.filter { run in
            calendar.isDate(run.date, equalTo: viewModel.displayedMonth, toGranularity: .month)
        }.count
    }
}
