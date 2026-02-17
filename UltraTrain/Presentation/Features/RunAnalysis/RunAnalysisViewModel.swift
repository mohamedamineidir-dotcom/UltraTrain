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

    // MARK: - State

    let run: CompletedRun
    var elevationProfile: [ElevationProfilePoint] = []
    var zoneDistribution: [HeartRateZoneDistribution] = []
    var routeSegments: [RouteSegment] = []
    var elevationSegments: [ElevationSegment] = []
    var routeColoringMode: RouteColoringMode = .pace
    var planComparison: PlanComparison?
    var checkpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var isLoading = false
    var error: String?
    var showFullScreenMap = false

    // MARK: - Init

    init(
        run: CompletedRun,
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository
    ) {
        self.run = run
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            let athlete = try await athleteRepository.getAthlete()

            elevationProfile = RunStatisticsCalculator.elevationProfile(from: run.gpsTrack)
            routeSegments = RunStatisticsCalculator.buildRouteSegments(from: run.gpsTrack)
            elevationSegments = RunStatisticsCalculator.buildElevationSegments(from: run.gpsTrack)

            let trackHasHR = run.gpsTrack.contains { $0.heartRate != nil }
            if let maxHR = athlete?.maxHeartRate, maxHR > 0, trackHasHR {
                zoneDistribution = RunStatisticsCalculator.heartRateZoneDistribution(
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
                }
            }

            if let raceId = run.linkedRaceId,
               let race = try await raceRepository.getRace(id: raceId),
               !race.checkpoints.isEmpty {
                checkpointLocations = CheckpointLocationResolver.resolveLocations(
                    checkpoints: race.checkpoints,
                    along: run.gpsTrack
                )
            }
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

    var hasRouteData: Bool {
        run.gpsTrack.count >= 2
    }

    var startCoordinate: (Double, Double)? {
        guard let first = run.gpsTrack.first else { return nil }
        return (first.latitude, first.longitude)
    }

    var endCoordinate: (Double, Double)? {
        guard let last = run.gpsTrack.last else { return nil }
        return (last.latitude, last.longitude)
    }
}
