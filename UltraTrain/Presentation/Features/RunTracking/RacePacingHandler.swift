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

    private let raceRepository: any RaceRepository
    private let runRepository: any RunRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let hapticService: any HapticServiceProtocol
    private let athlete: Athlete
    private let pacingAlertsEnabled: Bool

    // MARK: - Private

    private var raceCheckpoints: [Checkpoint] = []
    private var lastCheckpointResolveKm: Int = 0
    private var lastCrossedCheckpointIndex: Int = -1
    private var crossingBannerTask: Task<Void, Never>?
    private var pacingAlertTask: Task<Void, Never>?
    private var lastRacePacingAlertTime: TimeInterval = -.infinity
    private var lastRacePacingAlertType: PacingAlertType?
    private var lastSessionPacingAlertTime: TimeInterval = -.infinity
    private var lastSessionPacingAlertType: PacingAlertType?
    private var raceCheckpointSplits: [CheckpointSplit] = []
    private var raceExpectedFinishTime: TimeInterval = 0

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

    // MARK: - Pacing Alerts

    func checkPacingAlert(context: RunContext, linkedSession: TrainingSession?) {
        guard pacingAlertsEnabled, activePacingAlert == nil else { return }

        if isActive, let guidance = racePacingGuidance {
            let timeSinceLastAlert = context.elapsedTime - lastRacePacingAlertTime
            let input = RacePacingAlertCalculator.Input(
                currentPaceSecondsPerKm: context.runningAveragePace,
                segmentTargetPaceSecondsPerKm: guidance.targetPaceSecondsPerKm,
                segmentName: guidance.currentSegmentName,
                distanceKm: context.distanceKm,
                elapsedTimeSinceLastAlert: timeSinceLastAlert,
                previousAlertType: lastRacePacingAlertType
            )
            guard let alert = RacePacingAlertCalculator.evaluate(input) else { return }
            lastRacePacingAlertTime = context.elapsedTime
            lastRacePacingAlertType = alert.type
            showPacingAlert(alert)
            return
        }

        guard let session = linkedSession,
              session.plannedDistanceKm > 0,
              session.plannedDuration > 0 else { return }

        let plannedPace = session.plannedDuration / session.plannedDistanceKm
        let timeSinceLastAlert = context.elapsedTime - lastSessionPacingAlertTime

        let input = PacingAlertCalculator.Input(
            currentPaceSecondsPerKm: context.runningAveragePace,
            plannedPaceSecondsPerKm: plannedPace,
            distanceKm: context.distanceKm,
            elapsedTimeSinceLastAlert: timeSinceLastAlert,
            previousAlertType: lastSessionPacingAlertType
        )

        guard let alert = PacingAlertCalculator.evaluate(input) else { return }
        lastSessionPacingAlertTime = context.elapsedTime
        lastSessionPacingAlertType = alert.type
        showPacingAlert(alert)
    }

    func dismissPacingAlert() {
        activePacingAlert = nil
    }

    func dismissCrossingBanner() {
        activeCrossingBanner = nil
    }

    // MARK: - Private

    private func loadFinishEstimate(raceId: UUID) async {
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

    private func updateCheckpointLocations(context: RunContext) {
        guard !raceCheckpoints.isEmpty else { return }
        let currentKm = Int(context.distanceKm)
        guard currentKm > lastCheckpointResolveKm else { return }
        lastCheckpointResolveKm = currentKm
        resolvedCheckpointLocations = CheckpointLocationResolver.resolveLocations(
            checkpoints: raceCheckpoints,
            along: context.trackPoints
        )
    }

    private func detectCheckpointCrossings(context: RunContext) {
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

    private func showCrossingBanner(for checkpoint: LiveCheckpointState) {
        crossingBannerTask?.cancel()
        activeCrossingBanner = checkpoint
        hapticService.playSuccess()

        crossingBannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppConfiguration.LiveRace.crossingBannerDismissSeconds))
            guard !Task.isCancelled else { return }
            self?.activeCrossingBanner = nil
        }
    }

    private func showPacingAlert(_ alert: PacingAlert) {
        activePacingAlert = alert

        switch alert.severity {
        case .major: hapticService.playPacingAlertMajor()
        case .minor: hapticService.playPacingAlertMinor()
        case .positive: hapticService.playSuccess()
        }

        pacingAlertTask?.cancel()
        pacingAlertTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppConfiguration.PacingAlerts.autoDismissSeconds))
            guard !Task.isCancelled else { return }
            self?.activePacingAlert = nil
        }

        Logger.pacing.info("\(alert.type.rawValue) alert: \(alert.message)")
    }

    private func updatePacingGuidance(context: RunContext) {
        guard isActive, !raceSegmentPacings.isEmpty else { return }
        guard context.distanceKm >= AppConfiguration.LiveRace.guidanceUpdateMinDistanceKm else { return }
        guard context.runningAveragePace > 0 else { return }

        let segmentIndex = liveCheckpointStates.firstIndex { !$0.isCrossed } ?? liveCheckpointStates.count - 1
        guard segmentIndex < raceSegmentPacings.count else { return }

        let checkpoint = liveCheckpointStates[segmentIndex]
        let pacing = raceSegmentPacings[segmentIndex]
        let previousCheckpointDistance = segmentIndex > 0
            ? liveCheckpointStates[segmentIndex - 1].distanceFromStartKm : 0
        let segmentRemainingKm = max(0, checkpoint.distanceFromStartKm - context.distanceKm)

        let previousCheckpointTime = segmentIndex > 0
            ? (liveCheckpointStates[segmentIndex - 1].actualTime ?? liveCheckpointStates[segmentIndex - 1].predictedTime)
            : 0
        let segmentTargetDuration = pacing.targetPaceSecondsPerKm
            * (checkpoint.distanceFromStartKm - previousCheckpointDistance)
        let elapsedInSegment = context.elapsedTime - previousCheckpointTime
        let timeBudgetRemaining = max(0, segmentTargetDuration - elapsedInSegment)

        let projectedFinish = calculateTerrainAwareProjection(
            currentSegmentIndex: segmentIndex,
            elapsedTime: context.elapsedTime,
            distanceKm: context.distanceKm
        )

        let scenario: FinishScenario
        if projectedFinish < raceExpectedFinishTime * 0.98 {
            scenario = .aheadOfPlan
        } else if projectedFinish > raceExpectedFinishTime * 1.02 {
            scenario = .behindPlan
        } else {
            scenario = .onPlan
        }

        racePacingGuidance = RacePacingGuidance(
            currentSegmentIndex: segmentIndex,
            currentSegmentName: checkpoint.checkpointName,
            targetPaceSecondsPerKm: pacing.targetPaceSecondsPerKm,
            currentPaceSecondsPerKm: context.runningAveragePace,
            pacingZone: pacing.pacingZone,
            segmentTimeBudgetRemaining: timeBudgetRemaining,
            segmentDistanceRemainingKm: segmentRemainingKm,
            projectedFinishTime: projectedFinish,
            projectedFinishScenario: scenario
        )
    }

    private func calculateTerrainAwareProjection(
        currentSegmentIndex: Int,
        elapsedTime: TimeInterval,
        distanceKm: Double
    ) -> TimeInterval {
        var projected = elapsedTime
        for i in currentSegmentIndex..<raceSegmentPacings.count {
            let pacing = raceSegmentPacings[i]
            let checkpoint = liveCheckpointStates[i]
            let segmentStartKm = i > 0 ? liveCheckpointStates[i - 1].distanceFromStartKm : 0
            let segmentDistanceKm = checkpoint.distanceFromStartKm - segmentStartKm

            if i == currentSegmentIndex {
                let remainingKm = max(0, checkpoint.distanceFromStartKm - distanceKm)
                projected += remainingKm * pacing.targetPaceSecondsPerKm
            } else {
                projected += segmentDistanceKm * pacing.targetPaceSecondsPerKm
            }
            projected += pacing.aidStationDwellTime
        }
        return projected
    }

    private func recalculateRemainingPacing(crossedIndex: Int) {
        guard !raceSegmentPacings.isEmpty,
              !raceCheckpointSplits.isEmpty else { return }
        let state = liveCheckpointStates[crossedIndex]
        guard let actual = state.actualTime, state.predictedTime > 0 else { return }
        let deltaPercent = abs(actual - state.predictedTime) / state.predictedTime * 100
        guard deltaPercent >= AppConfiguration.LiveRace.recalculationDeltaThresholdPercent else { return }

        let input = RacePacingRecalculator.Input(
            segmentPacings: raceSegmentPacings,
            checkpointSplits: raceCheckpointSplits,
            crossedCheckpointIndex: crossedIndex,
            actualTimeAtCrossing: actual,
            predictedTimeAtCrossing: state.predictedTime,
            targetFinishTime: raceExpectedFinishTime
        )
        let result = RacePacingRecalculator.recalculate(input)
        raceSegmentPacings = result.updatedPacings
        Logger.liveRace.info("Recalculated pacing after checkpoint \(crossedIndex), new finish: \(result.recalculatedFinishTime)s")
    }
}
