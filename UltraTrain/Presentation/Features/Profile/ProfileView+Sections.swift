import SwiftUI

// MARK: - Athlete Helpers, Races, Gear, Routes, Challenges & Social Sections

extension ProfileView {

    // MARK: - Athlete Stats

    func athleteStatsGrid(_ athlete: Athlete) -> some View {
        Grid(alignment: .leading, horizontalSpacing: Theme.Spacing.lg, verticalSpacing: Theme.Spacing.sm) {
            GridRow {
                statItem(
                    label: "Weight",
                    value: String(format: "%.1f", UnitFormatter.weightValue(athlete.weightKg, unit: units)),
                    unit: UnitFormatter.weightLabel(units)
                )
                statItem(
                    label: "Height",
                    value: UnitFormatter.formatHeight(athlete.heightCm, unit: units),
                    unit: ""
                )
            }
            GridRow {
                statItem(label: "Resting HR", value: "\(athlete.restingHeartRate)", unit: "bpm")
                statItem(label: "Max HR", value: "\(athlete.maxHeartRate)", unit: "bpm")
            }
            GridRow {
                statItem(
                    label: "Weekly Vol",
                    value: String(format: "%.0f", UnitFormatter.distanceValue(athlete.weeklyVolumeKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
                statItem(
                    label: "Longest Run",
                    value: String(format: "%.0f", UnitFormatter.distanceValue(athlete.longestRunKm, unit: units)),
                    unit: UnitFormatter.distanceLabel(units)
                )
            }
        }
    }

    func statItem(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }

    // MARK: - Races Section

    var racesSection: some View {
        Section {
            NavigationLink {
                RaceCalendarGridView(
                    raceRepository: raceRepository,
                    planRepository: planRepository
                )
            } label: {
                Label("Race Calendar", systemImage: "calendar")
            }
            .accessibilityIdentifier("profile.raceCalendarLink")

            if viewModel.races.isEmpty {
                Label("No races configured", systemImage: "flag.checkered")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                if !viewModel.upcomingRaces.isEmpty {
                    upcomingRacesSubsection
                }
                if !viewModel.completedRaces.isEmpty {
                    completedRacesSubsection
                }
            }
        } header: {
            HStack {
                Text("Races")
                Spacer()
                Button {
                    viewModel.showingAddRace = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityLabel("Add Race")
                }
                .accessibilityIdentifier("profile.addRaceButton")
                .accessibilityHint("Opens the form to add a new race")
            }
        }
        .accessibilityIdentifier("profile.racesSection")
    }

    // MARK: - Upcoming Races

    @ViewBuilder
    var upcomingRacesSubsection: some View {
        Text("Upcoming")
            .font(.caption.bold())
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .listRowSeparator(.hidden)
        ForEach(viewModel.upcomingRaces) { race in
            NavigationLink {
                FinishEstimationView(
                    race: race,
                    finishTimeEstimator: finishTimeEstimator,
                    athleteRepository: athleteRepository,
                    runRepository: runRepository,
                    fitnessCalculator: fitnessCalculator,
                    nutritionRepository: nutritionRepository,
                    nutritionGenerator: nutritionGenerator,
                    raceRepository: raceRepository,
                    finishEstimateRepository: finishEstimateRepository,
                    weatherService: weatherService,
                    locationService: locationService,
                    checklistRepository: checklistRepository
                )
            } label: {
                RaceRowView(race: race)
            }
            .swipeActions(edge: .trailing) {
                Button("Edit") {
                    viewModel.raceToEdit = race
                }
                .tint(.blue)
                if race.date < Date.now {
                    Button("Complete") {
                        viewModel.showingPostRaceWizard = race
                    }
                    .tint(Theme.Colors.success)
                }
            }
        }
        .onDelete { indexSet in
            let upcoming = viewModel.upcomingRaces
            for index in indexSet {
                Task { await viewModel.deleteRace(id: upcoming[index].id) }
            }
        }
    }

    // MARK: - Completed Races

    @ViewBuilder
    var completedRacesSubsection: some View {
        Text("Completed")
            .font(.caption.bold())
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .listRowSeparator(.hidden)
        ForEach(viewModel.completedRaces) { race in
            NavigationLink {
                RaceReportView(
                    race: race,
                    raceReflectionRepository: raceReflectionRepository,
                    finishEstimateRepository: finishEstimateRepository,
                    runRepository: runRepository
                )
            } label: {
                HStack {
                    RaceRowView(race: race)
                    Spacer()
                    if let time = race.actualFinishTime {
                        Text(FinishEstimate.formatDuration(time))
                            .font(.caption.bold().monospacedDigit())
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Theme.Colors.success.opacity(0.15))
                            .foregroundStyle(Theme.Colors.success)
                            .clipShape(Capsule())
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                Button("Edit") {
                    viewModel.raceToEdit = race
                }
                .tint(.blue)
            }
        }
        .onDelete { indexSet in
            let completed = viewModel.completedRaces
            for index in indexSet {
                Task { await viewModel.deleteRace(id: completed[index].id) }
            }
        }
    }

    // MARK: - Gear Section

    var gearSection: some View {
        Section {
            NavigationLink {
                GearListView(
                    gearRepository: gearRepository,
                    runRepository: runRepository
                )
            } label: {
                Label("Gear", systemImage: "shoe.fill")
            }
            .accessibilityIdentifier("profile.gearLink")
        }
    }

    // MARK: - Routes Section

    var routesSection: some View {
        Section {
            NavigationLink {
                RouteLibraryView(
                    viewModel: RouteLibraryViewModel(
                        routeRepository: routeRepository,
                        runRepository: runRepository
                    )
                )
            } label: {
                Label("My Routes", systemImage: "map.fill")
            }
            .accessibilityIdentifier("profile.routesLink")
        }
    }

    // MARK: - Challenges Section

    var challengesSection: some View {
        Section {
            NavigationLink {
                ChallengesView(
                    challengeRepository: challengeRepository,
                    runRepository: runRepository,
                    athleteRepository: athleteRepository
                )
            } label: {
                Label("Challenges", systemImage: "trophy.fill")
            }
        }
    }

    // MARK: - Social Section

    var socialSection: some View {
        Section {
            NavigationLink {
                SocialTabView(
                    friendRepository: friendRepository,
                    profileRepository: socialProfileRepository,
                    athleteRepository: athleteRepository,
                    runRepository: runRepository,
                    activityFeedRepository: activityFeedRepository,
                    sharedRunRepository: sharedRunRepository,
                    crewService: crewService
                )
            } label: {
                Label("Social", systemImage: "person.2.fill")
            }

            NavigationLink {
                GroupChallengesView(
                    challengeRepository: groupChallengeRepository,
                    profileRepository: socialProfileRepository,
                    friendRepository: friendRepository
                )
            } label: {
                Label("Group Challenges", systemImage: "person.3.fill")
            }
        } header: {
            Text("Social")
        }
    }
}
