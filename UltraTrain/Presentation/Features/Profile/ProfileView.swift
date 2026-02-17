import SwiftUI

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: any HealthKitServiceProtocol
    private let exportService: any ExportServiceProtocol
    private let stravaAuthService: any StravaAuthServiceProtocol

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol,
        widgetDataWriter: WidgetDataWriter,
        exportService: any ExportServiceProtocol,
        stravaAuthService: any StravaAuthServiceProtocol
    ) {
        _viewModel = State(initialValue: ProfileViewModel(
            athleteRepository: athleteRepository,
            raceRepository: raceRepository,
            widgetDataWriter: widgetDataWriter
        ))
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
        self.fitnessCalculator = fitnessCalculator
        self.finishTimeEstimator = finishTimeEstimator
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.healthKitService = healthKitService
        self.exportService = exportService
        self.stravaAuthService = stravaAuthService
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    athleteSection
                    racesSection
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                if viewModel.athlete != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            viewModel.showingEditAthlete = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(
                            athleteRepository: athleteRepository,
                            appSettingsRepository: appSettingsRepository,
                            clearAllDataUseCase: clearAllDataUseCase,
                            healthKitService: healthKitService,
                            exportService: exportService,
                            runRepository: runRepository,
                            stravaAuthService: stravaAuthService
                        )
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .sheet(isPresented: $viewModel.showingEditAthlete) {
                if let athlete = viewModel.athlete {
                    EditAthleteSheet(athlete: athlete) { updated in
                        Task { await viewModel.updateAthlete(updated) }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddRace) {
                EditRaceSheet(mode: .add) { newRace in
                    Task { await viewModel.addRace(newRace) }
                }
            }
            .sheet(item: $viewModel.raceToEdit) { race in
                EditRaceSheet(mode: .edit(race)) { updated in
                    Task { await viewModel.updateRace(updated) }
                }
            }
        }
    }

    // MARK: - Athlete Section

    @ViewBuilder
    private var athleteSection: some View {
        if let athlete = viewModel.athlete {
            Section("Athlete") {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("\(athlete.firstName) \(athlete.lastName)")
                        .font(.title3.bold())
                    HStack(spacing: Theme.Spacing.md) {
                        Label("\(athlete.age) yrs", systemImage: "calendar")
                        Label(athlete.experienceLevel.rawValue.capitalized, systemImage: "figure.run")
                        Label(athlete.preferredUnit.rawValue.capitalized, systemImage: "ruler")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }
                athleteStatsGrid(athlete)
            }
        } else {
            Section("Athlete") {
                Label("Complete onboarding to see your profile", systemImage: "person.crop.circle")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    private func athleteStatsGrid(_ athlete: Athlete) -> some View {
        Grid(alignment: .leading, horizontalSpacing: Theme.Spacing.lg, verticalSpacing: Theme.Spacing.sm) {
            GridRow {
                statItem(label: "Weight", value: String(format: "%.1f", athlete.weightKg), unit: "kg")
                statItem(label: "Height", value: String(format: "%.0f", athlete.heightCm), unit: "cm")
            }
            GridRow {
                statItem(label: "Resting HR", value: "\(athlete.restingHeartRate)", unit: "bpm")
                statItem(label: "Max HR", value: "\(athlete.maxHeartRate)", unit: "bpm")
            }
            GridRow {
                statItem(label: "Weekly Vol", value: String(format: "%.0f", athlete.weeklyVolumeKm), unit: "km")
                statItem(label: "Longest Run", value: String(format: "%.0f", athlete.longestRunKm), unit: "km")
            }
        }
    }

    private func statItem(label: String, value: String, unit: String) -> some View {
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
    }

    // MARK: - Races Section

    private var racesSection: some View {
        Section {
            if viewModel.races.isEmpty {
                Label("No races configured", systemImage: "flag.checkered")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(viewModel.sortedRaces) { race in
                    NavigationLink {
                        FinishEstimationView(
                            race: race,
                            finishTimeEstimator: finishTimeEstimator,
                            athleteRepository: athleteRepository,
                            runRepository: runRepository,
                            fitnessCalculator: fitnessCalculator
                        )
                    } label: {
                        RaceRowView(race: race)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Edit") {
                            viewModel.raceToEdit = race
                        }
                        .tint(.blue)
                    }
                }
                .onDelete { indexSet in
                    let sorted = viewModel.sortedRaces
                    for index in indexSet {
                        Task { await viewModel.deleteRace(id: sorted[index].id) }
                    }
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
                }
            }
        }
    }

}
