import CoreLocation
import Foundation
import os

@Observable
@MainActor
final class RunAnalysisViewModel {

    // MARK: - Dependencies

    private let planRepository: any TrainingPlanRepository
    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let runRepository: any RunRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let exportService: any ExportServiceProtocol

    // MARK: - State

    let run: CompletedRun
    var elevationProfile: [ElevationProfilePoint] = []
    var zoneDistribution: [HeartRateZoneDistribution] = []
    var routeSegments: [RouteSegment] = []
    var elevationSegments: [ElevationSegment] = []
    var heartRateSegments: [HeartRateSegment] = []
    var distanceMarkers: [(km: Int, coordinate: (Double, Double))] = []
    var segmentDetails: [SegmentDetail] = []
    var selectedSegment: SegmentDetail?
    var routeColoringMode: RouteColoringMode = .pace
    var planComparison: PlanComparison?
    var checkpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var advancedMetrics: AdvancedRunMetrics?
    var historicalComparison: HistoricalComparison?
    var nutritionAnalysis: NutritionAnalysis?
    var racePerformance: RacePerformanceComparison?
    var routeComparison: RouteComparisonCalculator.RouteComparison?
    var linkedRaceCourseRoute: [TrackPoint]?
    var zoneCompliance: ZoneComplianceCalculator.ZoneCompliance?
    var trainingStressScore: Double?
    var paceDistribution: [PaceDistributionCalculator.PaceBucket] = []
    var gradientPacePoints: [ElevationPaceScatterCalculator.GradientPacePoint] = []
    var isLoading = false
    var error: String?
    var showFullScreenMap = false

    // MARK: - Export State

    var showingExportOptions = false
    var exportFileURL: URL?
    var showingShareSheet = false
    var isExporting = false
    var exportError: String?

    // MARK: - Init

    init(
        run: CompletedRun,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        runRepository: any RunRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        exportService: any ExportServiceProtocol
    ) {
        self.run = run
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.runRepository = runRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.exportService = exportService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            let athlete = try await athleteRepository.getAthlete()

            elevationProfile = ElevationCalculator.elevationProfile(from: run.gpsTrack)
            routeSegments = RunStatisticsCalculator.buildRouteSegments(from: run.gpsTrack)
            elevationSegments = ElevationCalculator.buildElevationSegments(from: run.gpsTrack)

            paceDistribution = PaceDistributionCalculator.compute(trackPoints: run.gpsTrack)
            if run.gpsTrack.count >= 10 {
                gradientPacePoints = ElevationPaceScatterCalculator.compute(trackPoints: run.gpsTrack)
            }

            distanceMarkers = RunStatisticsCalculator.buildDistanceMarkers(from: run.gpsTrack)
            segmentDetails = RunStatisticsCalculator.buildSegmentDetails(
                from: run.gpsTrack,
                splits: run.splits,
                maxHeartRate: athlete?.maxHeartRate
            )

            let trackHasHR = run.gpsTrack.contains { $0.heartRate != nil }
            if let maxHR = athlete?.maxHeartRate, maxHR > 0, trackHasHR {
                zoneDistribution = RunStatisticsCalculator.heartRateZoneDistribution(
                    from: run.gpsTrack,
                    maxHeartRate: maxHR
                )
                heartRateSegments = RunStatisticsCalculator.buildHeartRateSegments(
                    from: run.gpsTrack,
                    maxHeartRate: maxHR
                )
            }

            if let sessionId = run.linkedSessionId,
               let plan = try await planRepository.getActivePlan() {
                let allSessions = plan.weeks.flatMap(\.sessions)
                if let session = allSessions.first(where: { $0.id == sessionId }) {
                    planComparison = RunStatisticsCalculator.buildPlanComparison(
                        run: run,
                        session: session
                    )
                    if let targetZone = session.targetHeartRateZone,
                       let maxHR = athlete?.maxHeartRate, maxHR > 0,
                       run.gpsTrack.count >= 2 {
                        zoneCompliance = ZoneComplianceCalculator.calculate(
                            trackPoints: run.gpsTrack,
                            targetZone: targetZone,
                            maxHeartRate: maxHR,
                            customThresholds: athlete?.customZoneThresholds
                        )
                    }
                }
            }

            if let raceId = run.linkedRaceId,
               let race = try await raceRepository.getRace(id: raceId) {
                if !race.checkpoints.isEmpty {
                    checkpointLocations = CheckpointLocationResolver.resolveLocations(
                        checkpoints: race.checkpoints,
                        along: run.gpsTrack
                    )

                    if let estimate = try await finishEstimateRepository.getEstimate(for: raceId),
                       !estimate.checkpointSplits.isEmpty,
                       run.gpsTrack.count >= 2,
                       let runStart = run.gpsTrack.first?.timestamp {

                        let timestamps = CheckpointLocationResolver.resolveTimestamps(
                            checkpoints: race.checkpoints,
                            along: run.gpsTrack
                        )

                        let comparisons = estimate.checkpointSplits.compactMap { split -> CheckpointComparison? in
                            guard let match = timestamps.first(where: { $0.checkpoint.id == split.checkpointId }) else {
                                return nil
                            }
                            let actualSeconds = match.timestamp.timeIntervalSince(runStart)
                            return CheckpointComparison(
                                id: split.id,
                                checkpointName: split.checkpointName,
                                distanceFromStartKm: split.distanceFromStartKm,
                                hasAidStation: split.hasAidStation,
                                predictedTime: split.expectedTime,
                                actualTime: actualSeconds,
                                delta: actualSeconds - split.expectedTime
                            )
                        }

                        if !comparisons.isEmpty {
                            racePerformance = RacePerformanceComparison(
                                checkpointComparisons: comparisons,
                                predictedFinishTime: estimate.expectedTime,
                                actualFinishTime: run.duration,
                                finishDelta: run.duration - estimate.expectedTime
                            )
                        }
                    }
                }

                if race.hasCourseRoute, run.gpsTrack.count >= 2 {
                    linkedRaceCourseRoute = race.courseRoute
                    routeComparison = RouteComparisonCalculator.compare(
                        actual: run.gpsTrack,
                        planned: race.courseRoute
                    )
                }
            }

            advancedMetrics = AdvancedRunMetricsCalculator.calculate(
                run: run,
                athleteWeightKg: athlete?.weightKg,
                maxHeartRate: athlete?.maxHeartRate
            )

            if let athlete {
                trainingStressScore = TrainingStressCalculator.calculate(
                    run: run,
                    maxHeartRate: athlete.maxHeartRate,
                    restingHeartRate: athlete.restingHeartRate,
                    customThresholds: athlete.customZoneThresholds
                )
            }

            let recentRuns = try await runRepository.getRecentRuns(limit: 20)
            let otherRuns = recentRuns.filter { $0.id != run.id }
            if !otherRuns.isEmpty {
                historicalComparison = HistoricalComparisonCalculator.compare(
                    run: run,
                    recentRuns: otherRuns
                )
            }

            nutritionAnalysis = NutritionAnalysisCalculator.analyze(run: run)
        } catch {
            self.error = error.localizedDescription
            Logger.analysis.error("Failed to load run analysis: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed

    var hasHeartRateData: Bool {
        !zoneDistribution.isEmpty && zoneDistribution.contains { $0.durationSeconds > 0 }
    }

    var hasLinkedSession: Bool {
        planComparison != nil
    }

    var hasAdvancedMetrics: Bool { advancedMetrics != nil }

    var hasHistoricalComparison: Bool { historicalComparison != nil }

    var hasNutritionAnalysis: Bool { nutritionAnalysis != nil }

    var hasRacePerformance: Bool { racePerformance != nil }

    var hasZoneCompliance: Bool { zoneCompliance != nil }

    var hasRouteComparison: Bool {
        routeComparison != nil && linkedRaceCourseRoute != nil
    }

    var hasRouteData: Bool {
        run.gpsTrack.count >= 2
    }

    var splitPaceMap: [Int: Double] {
        Dictionary(uniqueKeysWithValues: run.splits.map { ($0.kilometerNumber, $0.duration) })
    }

    var checkpointDistanceNames: [(name: String, distanceKm: Double)] {
        checkpointLocations.map { (name: $0.checkpoint.name, distanceKm: $0.checkpoint.distanceFromStartKm) }
    }

    var startCoordinate: (Double, Double)? {
        guard let first = run.gpsTrack.first else { return nil }
        return (first.latitude, first.longitude)
    }

    var endCoordinate: (Double, Double)? {
        guard let last = run.gpsTrack.last else { return nil }
        return (last.latitude, last.longitude)
    }

    // MARK: - Export

    func exportAsShareImage(unitPreference: UnitPreference) async {
        isExporting = true
        exportError = nil
        do {
            let badges = historicalComparison?.badges ?? []
            exportFileURL = try await exportService.exportRunAsShareImage(
                run,
                elevationProfile: elevationProfile,
                metrics: advancedMetrics,
                badges: badges,
                unitPreference: unitPreference
            )
            showingShareSheet = true
        } catch {
            exportError = "Failed to create share image."
            Logger.export.error("Share image export failed: \(error)")
        }
        isExporting = false
    }

    func exportAsGPX() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await exportService.exportRunAsGPX(run)
            showingShareSheet = true
        } catch {
            exportError = "Failed to export GPX."
            Logger.export.error("GPX export failed: \(error)")
        }
        isExporting = false
    }

    func exportAsTrackCSV() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await exportService.exportRunTrackAsCSV(run)
            showingShareSheet = true
        } catch {
            exportError = "Failed to export CSV."
            Logger.export.error("CSV export failed: \(error)")
        }
        isExporting = false
    }

    func exportAsPDF() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await exportService.exportRunAsPDF(
                run,
                metrics: advancedMetrics,
                comparison: historicalComparison,
                nutritionAnalysis: nutritionAnalysis
            )
            showingShareSheet = true
        } catch {
            exportError = "Failed to export PDF."
            Logger.export.error("PDF export failed: \(error)")
        }
        isExporting = false
    }
}
