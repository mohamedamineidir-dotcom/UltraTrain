import SwiftUI
import UniformTypeIdentifiers

struct RunHistoryView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48
    @State private var viewModel: RunHistoryViewModel
    @State private var showingDocumentPicker = false
    @State private var importFileURL: URL?
    @State private var showingStravaImport = false
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let exportService: any ExportServiceProtocol
    private let runImportUseCase: any RunImportUseCase
    private let stravaUploadService: (any StravaUploadServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?
    private let stravaConnected: Bool

    init(
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        exportService: any ExportServiceProtocol,
        runImportUseCase: any RunImportUseCase,
        stravaUploadService: (any StravaUploadServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        stravaConnected: Bool = false
    ) {
        _viewModel = State(initialValue: RunHistoryViewModel(runRepository: runRepository))
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.exportService = exportService
        self.runImportUseCase = runImportUseCase
        self.stravaUploadService = stravaUploadService
        self.stravaImportService = stravaImportService
        self.stravaConnected = stravaConnected
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sortedRuns.isEmpty {
                emptyState
            } else {
                runList
            }
        }
        .navigationTitle("Run History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        .task { await viewModel.load() }
    }

    // MARK: - List

    private var runList: some View {
        List {
            ForEach(viewModel.sortedRuns) { run in
                NavigationLink(value: run.id) {
                    RunHistoryRow(run: run)
                }
            }
            .onDelete { indexSet in
                let sorted = viewModel.sortedRuns
                for index in indexSet {
                    Task { await viewModel.deleteRun(id: sorted[index].id) }
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
                    stravaUploadService: stravaUploadService,
                    stravaConnected: stravaConnected
                )
            }
        }
    }

    // MARK: - Empty

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
}

// MARK: - Row

private struct RunHistoryRow: View {
    let run: CompletedRun

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(run.date, style: .date)
                    .font(.subheadline.bold())
                Spacer()
                Text(RunStatisticsCalculator.formatDuration(run.duration))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            HStack(spacing: Theme.Spacing.md) {
                Label(
                    String(format: "%.2f km", run.distanceKm),
                    systemImage: "arrow.left.arrow.right"
                )
                Label(run.paceFormatted, systemImage: "speedometer")
                if run.elevationGainM > 0 {
                    Label(
                        String(format: "+%.0f m", run.elevationGainM),
                        systemImage: "arrow.up.right"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
