import SwiftUI

struct RaceCalendarGridView: View {
    @State private var viewModel: RaceCalendarGridViewModel

    init(
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository
    ) {
        _viewModel = State(initialValue: RaceCalendarGridViewModel(
            raceRepository: raceRepository,
            planRepository: planRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                CalendarMonthGridView(
                    displayedMonth: viewModel.displayedMonth,
                    phaseForDate: viewModel.phaseForDate,
                    raceForDate: viewModel.raceForDate,
                    sessionsForDate: viewModel.sessionsForDate,
                    selectedDate: $viewModel.selectedDate,
                    onNavigate: { viewModel.navigateMonth(by: $0) }
                )

                CalendarLegendView()

                if !viewModel.upcomingRaces.isEmpty {
                    upcomingRacesSection
                }
            }
            .padding()
        }
        .navigationTitle("Race Calendar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingAddRace = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add race")
                .accessibilityHint("Opens form to add a new race")
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(item: $viewModel.selectedDate) { date in
            CalendarDayDetailSheet(
                date: date,
                phase: viewModel.phaseForDate(date),
                sessions: viewModel.sessionsForDate(date),
                race: viewModel.raceForDate(date),
                onEditRace: { race in
                    viewModel.selectedDate = nil
                    viewModel.raceToEdit = race
                },
                onDeleteRace: { id in
                    viewModel.selectedDate = nil
                    Task { await viewModel.deleteRace(id: id) }
                }
            )
        }
        .sheet(isPresented: $viewModel.showingAddRace) {
            EditRaceSheet(mode: .add) { race in
                Task { await viewModel.addRace(race) }
            }
        }
        .sheet(item: $viewModel.raceToEdit) { race in
            EditRaceSheet(mode: .edit(race)) { updated in
                Task { await viewModel.updateRace(updated) }
            }
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

    // MARK: - Upcoming Races

    private var upcomingRacesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Upcoming Races")
                .font(.headline)

            ForEach(viewModel.upcomingRaces) { race in
                Button {
                    viewModel.selectedDate = race.date
                } label: {
                    UpcomingRaceRow(race: race)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Date + Identifiable for sheet

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
