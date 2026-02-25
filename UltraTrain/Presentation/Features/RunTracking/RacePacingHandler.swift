import CoreLocation
import Foundation
import os

@Observable
@MainActor
final class RacePacingHandler {

    // MARK: - State

    var resolvedCheckpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var liveCheckpointStates: [LiveCheckpointState] = []
    var activeCrossingBanner: LiveCheckpointState?
    var racePacingGuidance: RacePacingGuidance?
    var raceSegmentPacings: [TerrainAdaptivePacingCalculator.AdaptiveSegmentPacing] = []
    var raceDistanceKm: Double = 0
    var activePacingAlert: PacingAlert?

    // MARK: - Dependencies

    let raceRepository: any RaceRepository
    let runRepository: any RunRepository
    let finishEstimateRepository: any FinishEstimateRepository
    let hapticService: any HapticServiceProtocol
    let athlete: Athlete
    let pacingAlertsEnabled: Bool

    // MARK: - Private

    var raceCheckpoints: [Checkpoint] = []
    var lastCheckpointResolveKm: Int = 0
    var lastCrossedCheckpointIndex: Int = -1
    var crossingBannerTask: Task<Void, Never>?
    var pacingAlertTask: Task<Void, Never>?
    var lastRacePacingAlertTime: TimeInterval = -.infinity
    var lastRacePacingAlertType: PacingAlertType?
    var lastSessionPacingAlertTime: TimeInterval = -.infinity
    var lastSessionPacingAlertType: PacingAlertType?
    var raceCheckpointSplits: [CheckpointSplit] = []
    var raceExpectedFinishTime: TimeInterval = 0

    // MARK: - Context

    struct RunContext: Sendable {
        let distanceKm: Double
        let elapsedTime: TimeInterval
        let runningAveragePace: Double
        let trackPoints: [TrackPoint]
    }

    // MARK: - Init

    init(
        raceRepository: any RaceRepository,
        runRepository: any RunRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        hapticService: any HapticServiceProtocol,
        athlete: Athlete,
        pacingAlertsEnabled: Bool
    ) {
        self.raceRepository = raceRepository
        self.runRepository = runRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.hapticService = hapticService
        self.athlete = athlete
        self.pacingAlertsEnabled = pacingAlertsEnabled
    }

    // MARK: - Computed

    var isActive: Bool {
        !liveCheckpointStates.isEmpty
    }

    var nextCheckpoint: LiveCheckpointState? {
        liveCheckpointStates.first { !$0.isCrossed }
    }

    func distanceToNextCheckpointKm(currentDistanceKm: Double) -> Double? {
        guard let next = nextCheckpoint else { return nil }
        return max(0, next.distanceFromStartKm - currentDistanceKm)
    }

    func projectedFinishTime(context: RunContext) -> TimeInterval? {
        if let guidance = racePacingGuidance {
            return guidance.projectedFinishTime
        }
        guard context.distanceKm > 0.5, raceDistanceKm > 0 else { return nil }
        let remainingKm = max(0, raceDistanceKm - context.distanceKm)
        let pacePerKm = context.elapsedTime / context.distanceKm
        return context.elapsedTime + (remainingKm * pacePerKm)
    }

    // MARK: - Load

    func loadRace(raceId: UUID) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let race = try await self.raceRepository.getRace(id: raceId) {
                    self.raceCheckpoints = race.checkpoints
                    self.raceDistanceKm = race.distanceKm
                    Logger.tracking.info("Loaded \(race.checkpoints.count) checkpoints for race \(race.name)")
                    await self.loadFinishEstimate(raceId: raceId)
                }
            } catch {
                Logger.tracking.error("Failed to load race checkpoints: \(error)")
            }
        }
    }

    // MARK: - Process Location

    func processLocation(context: RunContext) {
        updateCheckpointLocations(context: context)
        detectCheckpointCrossings(context: context)
        updatePacingGuidance(context: context)
    }

    // MARK: - Dismiss

    func dismissPacingAlert() {
        activePacingAlert = nil
    }

    func dismissCrossingBanner() {
        activeCrossingBanner = nil
    }

    // MARK: - Private — Checkpoint

    func loadFinishEstimate(raceId: UUID) async {
        do {
            guard let estimate = try await finishEstimateRepository.getEstimate(for: raceId) else {
                Logger.liveRace.info("No saved estimate for race \(raceId) — live splits unavailable")
                return
            }
            liveCheckpointStates = estimate.checkpointSplits.map { split in
                LiveCheckpointState(
                    id: split.checkpointId,
                    checkpointName: split.checkpointName,
                    distanceFromStartKm: split.distanceFromStartKm,
                    hasAidStation: split.hasAidStation,
                    predictedTime: split.expectedTime
                )
            }
            raceCheckpointSplits = estimate.checkpointSplits
            raceExpectedFinishTime = estimate.expectedTime

            let runs = try await runRepository.getRuns(for: athlete.id)
            let adaptiveInput = TerrainAdaptivePacingCalculator.AdaptiveInput(
                checkpointSplits: estimate.checkpointSplits,
                defaultAidStationDwellSeconds: AppConfiguration.PacingStrategy.defaultAidStationDwellSeconds,
                aidStationDwellOverrides: [:],
                pacingMode: .pace,
                athlete: athlete,
                recentRuns: runs
            )
            let result = TerrainAdaptivePacingCalculator.calculate(adaptiveInput)
            raceSegmentPacings = result.segmentPacings
            Logger.liveRace.info("Loaded \(self.liveCheckpointStates.count) live checkpoint states with adaptive pacing")
        } catch {
            Logger.liveRace.error("Failed to load finish estimate: \(error)")
        }
    }

    func updateCheckpointLocations(context: RunContext) {
        guard !raceCheckpoints.isEmpty else { return }
        let currentKm = Int(context.distanceKm)
        guard currentKm > lastCheckpointResolveKm else { return }
        lastCheckpointResolveKm = currentKm
        resolvedCheckpointLocations = CheckpointLocationResolver.resolveLocations(
            checkpoints: raceCheckpoints,
            along: context.trackPoints
        )
    }

    func detectCheckpointCrossings(context: RunContext) {
        guard !liveCheckpointStates.isEmpty else { return }

        for i in 0..<liveCheckpointStates.count {
            guard !liveCheckpointStates[i].isCrossed else { continue }
            guard context.distanceKm >= liveCheckpointStates[i].distanceFromStartKm else { break }

            liveCheckpointStates[i].actualTime = context.elapsedTime
            lastCrossedCheckpointIndex = i
            showCrossingBanner(for: liveCheckpointStates[i])
            recalculateRemainingPacing(crossedIndex: i)
            Logger.liveRace.info("Crossed checkpoint \(self.liveCheckpointStates[i].checkpointName) at \(context.elapsedTime)s")
        }
    }
}
