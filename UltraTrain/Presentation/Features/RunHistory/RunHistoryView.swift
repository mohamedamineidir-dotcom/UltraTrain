import SwiftUI
import UniformTypeIdentifiers

struct RunHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48
    @State private var viewModel: RunHistoryViewModel
    @State private var showingDocumentPicker = false
    @State private var importFileURL: URL?
    @State private var showingStravaImport = false
    @State private var showingFilterSheet = false
    @State private var deleteConfirmation: CompletedRun?
    @State private var selectedRunId: UUID?
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
    private let athleteId: UUID?

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
        gearRepository: (any GearRepository)? = nil,
        athleteId: UUID? = nil
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
        self.athleteId = athleteId
    }

    private var resolvedAthleteId: UUID {
        athleteId ?? viewModel.runs.first?.athleteId ?? UUID()
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
                    athleteId: resolvedAthleteId,
                    runImportUseCase: runImportUseCase
                )
            }
        }
        .sheet(isPresented: $showingStravaImport) {
            if let service = stravaImportService {
                StravaImportView(
                    importService: service,
                    athleteId: resolvedAthleteId
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
        .confirmationDialog(
            "Delete this run?",
            isPresented: Binding(
                get: { deleteConfirmation != nil },
                set: { if !$0 { deleteConfirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let run = deleteConfirmation {
                    Task { await viewModel.deleteRun(id: run.id) }
                }
                deleteConfirmation = nil
            }
            Button("Cancel", role: .cancel) {
                deleteConfirmation = nil
            }
        } message: {
            Text("This run will be permanently deleted. This cannot be undone.")
        }
        .task { await viewModel.load() }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: - List

    private var runList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                // Filter bar
                RunHistoryFilterBar(
                    selectedPeriod: $viewModel.selectedTimePeriod,
                    customStartDate: $viewModel.customStartDate,
                    customEndDate: $viewModel.customEndDate
                )
                .padding(.horizontal, Theme.Spacing.md)

                // Summary header
                RunHistorySummaryHeader(
                    runCount: viewModel.filteredRunCount,
                    totalDistanceKm: viewModel.filteredTotalDistanceKm,
                    totalElevationM: viewModel.filteredTotalElevationM,
                    totalDuration: viewModel.filteredTotalDuration
                )
                .padding(.horizontal, Theme.Spacing.md)

                // Run list
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredRuns) { run in
                        Button {
                            selectedRunId = run.id
                        } label: {
                            RunHistoryRow(run: run)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteConfirmation = run
                            } label: {
                                Label("Delete Run", systemImage: "trash")
                            }
                        }

                        if run.id != viewModel.filteredRuns.last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .futuristicGlassStyle()
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .navigationDestination(item: $selectedRunId) { runId in
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
            } else {
                ContentUnavailableView(
                    "Run Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This run may have been deleted.")
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
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.warmCoral.opacity(colorScheme == .dark ? 0.12 : 0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.run.circle")
                    .font(.system(size: emptyIconSize))
                    .foregroundStyle(Theme.Colors.warmCoral)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("No runs yet")
                    .font(.title3.bold())
                Text("Your completed runs will appear here.\nRecord a run or import from Strava.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Theme.Spacing.md) {
                Button {
                    showingDocumentPicker = true
                } label: {
                    Label("Import GPX", systemImage: "doc.badge.arrow.up")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(Capsule())
                }

                if stravaConnected {
                    Button {
                        showingStravaImport = true
                    } label: {
                        Label("Strava", systemImage: "arrow.down.circle")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, Theme.Spacing.sm)

            Spacer()
        }
        .padding()
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
            Text("No matching runs")
                .font(.title3.bold())
            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Button("Clear Filters") {
                viewModel.clearFilters()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.Colors.warmCoral)
            .padding(.top, Theme.Spacing.sm)

            Spacer()
        }
    }
}
