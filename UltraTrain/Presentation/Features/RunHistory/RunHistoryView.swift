import SwiftUI
import UniformTypeIdentifiers

struct RunHistoryView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48
    @State private var viewModel: RunHistoryViewModel
    @State private var showingDocumentPicker = false
    @State private var importFileURL: URL?
    @State private var showingStravaImport = false
    @State private var showingFilterSheet = false
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let exportService: any ExportServiceProtocol
    private let runImportUseCase: any RunImportUseCase
    private let stravaUploadService: (any StravaUploadServiceProtocol)?
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?
    private let stravaConnected: Bool
    private let finishEstimateRepository: any FinishEstimateRepository
    private let gearRepository: (any GearRepository)?

    init(
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        exportService: any ExportServiceProtocol,
        runImportUseCase: any RunImportUseCase,
        stravaUploadService: (any StravaUploadServiceProtocol)? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        stravaConnected: Bool = false,
        finishEstimateRepository: any FinishEstimateRepository,
        gearRepository: (any GearRepository)? = nil
    ) {
        _viewModel = State(initialValue: RunHistoryViewModel(
            runRepository: runRepository,
            planRepository: planRepository,
            gearRepository: gearRepository
        ))
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.exportService = exportService
        self.runImportUseCase = runImportUseCase
        self.stravaUploadService = stravaUploadService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.stravaImportService = stravaImportService
        self.stravaConnected = stravaConnected
        self.finishEstimateRepository = finishEstimateRepository
        self.gearRepository = gearRepository
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.runs.isEmpty {
                emptyState
            } else if viewModel.filteredRuns.isEmpty {
                noResultsState
            } else {
                runList
            }
        }
        .navigationTitle("Run History")
        .searchable(text: $viewModel.searchText, prompt: "Search notes")
        .onChange(of: viewModel.searchText) { _, newValue in
            viewModel.debounceSearch(newValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: Theme.Spacing.sm) {
                    sortMenu
                    RunHistoryFilterBadge(
                        activeCount: viewModel.activeFilterCount
                    ) {
                        showingFilterSheet = true
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                importMenu
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(contentTypes: [.xml]) { url in
                importFileURL = url
            }
        }
        .sheet(isPresented: Binding(
            get: { importFileURL != nil },
            set: { if !$0 {
                importFileURL = nil
                Task { await viewModel.load() }
            }}
        )) {
            if let url = importFileURL {
                ImportRunView(
                    fileURL: url,
                    athleteId: viewModel.runs.first?.athleteId ?? UUID(),
                    runImportUseCase: runImportUseCase
                )
            }
        }
        .sheet(isPresented: $showingStravaImport) {
            if let service = stravaImportService {
                StravaImportView(
                    importService: service,
                    athleteId: viewModel.runs.first?.athleteId ?? UUID()
                ) {
                    Task { await viewModel.load() }
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            RunHistoryFilterSheet(
                filter: $viewModel.advancedFilter,
                availableSessionTypes: viewModel.availableSessionTypes,
                availableGear: viewModel.availableGear
            )
        }
        .task { await viewModel.load() }
    }

    // MARK: - List

    private var runList: some View {
        List {
            Section {
                RunHistoryFilterBar(
                    selectedPeriod: $viewModel.selectedTimePeriod,
                    customStartDate: $viewModel.customStartDate,
                    customEndDate: $viewModel.customEndDate
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                RunHistorySummaryHeader(
                    runCount: viewModel.filteredRunCount,
                    totalDistanceKm: viewModel.filteredTotalDistanceKm,
                    totalElevationM: viewModel.filteredTotalElevationM,
                    totalDuration: viewModel.filteredTotalDuration
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(viewModel.filteredRuns) { run in
                    NavigationLink(value: run.id) {
                        RunHistoryRow(run: run)
                    }
                }
                .onDelete { indexSet in
                    let filtered = viewModel.filteredRuns
                    for index in indexSet {
                        Task { await viewModel.deleteRun(id: filtered[index].id) }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: UUID.self) { runId in
            if let run = viewModel.runs.first(where: { $0.id == runId }) {
                RunDetailView(
                    run: run,
                    planRepository: planRepository,
                    athleteRepository: athleteRepository,
                    raceRepository: raceRepository,
                    runRepository: runRepository,
                    exportService: exportService,
                    stravaUploadQueueService: stravaUploadQueueService,
                    stravaConnected: stravaConnected,
                    finishEstimateRepository: finishEstimateRepository
                )
            }
        }
    }

    // MARK: - Toolbar

    private var sortMenu: some View {
        Menu {
            ForEach(RunSortOption.allCases) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    if viewModel.sortOption == option {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort")
        .accessibilityHint("Changes run sort order")
    }

    private var importMenu: some View {
        Menu {
            Button {
                showingDocumentPicker = true
            } label: {
                Label("Import GPX File", systemImage: "doc.badge.arrow.up")
            }
            if stravaConnected {
                Button {
                    showingStravaImport = true
                } label: {
                    Label("Import from Strava", systemImage: "arrow.down.circle")
                }
            }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Import run")
        .accessibilityHint("Opens import options")
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: emptyIconSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("No runs yet")
                .font(.headline)
            Text("Your completed runs will appear here.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: Theme.Spacing.md) {
            RunHistoryFilterBar(
                selectedPeriod: $viewModel.selectedTimePeriod,
                customStartDate: $viewModel.customStartDate,
                customEndDate: $viewModel.customEndDate
            )
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: emptyIconSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            Text("No matching runs")
                .font(.headline)
            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Spacer()
        }
    }
}
