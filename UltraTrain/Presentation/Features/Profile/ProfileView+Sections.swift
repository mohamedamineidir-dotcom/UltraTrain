import SwiftUI

// MARK: - Athlete Helpers, Races, Gear, Routes, Challenges & Social Sections

extension ProfileView {

    // MARK: - Athlete Stats

    func athleteStatsGrid(_ athlete: Athlete) -> some View {
        // 3 columns × 2 rows. Row 1 = body baseline + resting HR;
        // Row 2 = max HR + training capacity (weekly volume + longest
        // run). Same six stats as before, just denser so the athlete
        // card stops eating half the screen.
        Grid(alignment: .leading, horizontalSpacing: Theme.Spacing.md, verticalSpacing: Theme.Spacing.sm) {
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
                statItem(label: "Resting HR", value: "\(athlete.restingHeartRate)", unit: "bpm")
            }
            GridRow {
                statItem(label: "Max HR", value: "\(athlete.maxHeartRate)", unit: "bpm")
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
            Text(LocalizedStringKey(label))
                .textCase(.uppercase)
                .font(.caption2.weight(.semibold))
                .tracking(0.4)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Theme.Colors.label)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
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
                    // Custom races are premium: free users get the paywall.
                    if premiumGate?.isUnlocked == false {
                        premiumGate?.presentPaywall()
                    } else {
                        viewModel.showingAddRace = true
                    }
                } label: {
                    Image(systemName: premiumGate?.isUnlocked == false
                          ? "lock.circle.fill" : "plus.circle.fill")
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
        // Subtitle was sitting in a default List row (~12pt top + 12pt
        // bottom inset) which left a visible gap above and below
        // "Upcoming". Trim to a tight 6pt top / 2pt bottom so the
        // subtitle hugs the first race row beneath it.
        Text("Upcoming")
            .font(.caption.bold())
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 2, trailing: 16))
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
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 12))
            .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive) {
                    viewModel.raceToDelete = race
                }
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
    }

    // MARK: - Completed Races

    @ViewBuilder
    var completedRacesSubsection: some View {
        Text("Completed")
            .font(.caption.bold())
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 2, trailing: 16))
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
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 12))
            .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive) {
                    viewModel.raceToDelete = race
                }
                Button("Edit") {
                    viewModel.raceToEdit = race
                }
                .tint(.blue)
            }
        }
    }

    // MARK: - Personal Records Section

    var personalRecordsSection: some View {
        Section {
            NavigationLink {
                PersonalRecordsView(viewModel: viewModel)
            } label: {
                Label(
                    String(localized: "profile.personalRecords", defaultValue: "Personal records"),
                    systemImage: "stopwatch"
                )
            }
            .accessibilityIdentifier("profile.personalRecordsLink")
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
