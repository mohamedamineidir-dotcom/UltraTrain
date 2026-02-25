import Foundation
import os

extension RacePacingHandler {

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

    // MARK: - Private — Banners & Alerts

    func showCrossingBanner(for checkpoint: LiveCheckpointState) {
        crossingBannerTask?.cancel()
        activeCrossingBanner = checkpoint
        hapticService.playSuccess()

        crossingBannerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppConfiguration.LiveRace.crossingBannerDismissSeconds))
            guard !Task.isCancelled else { return }
            self?.activeCrossingBanner = nil
        }
    }

    func showPacingAlert(_ alert: PacingAlert) {
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

    // MARK: - Private — Pacing Guidance

    func updatePacingGuidance(context: RunContext) {
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

    func calculateTerrainAwareProjection(
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

    func recalculateRemainingPacing(crossedIndex: Int) {
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
