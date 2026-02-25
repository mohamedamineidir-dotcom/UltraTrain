import Foundation
import os

extension IntervalGuidanceHandler {

    // MARK: - Phase Transition

    func checkPhaseTransition(context: RunContext) {
        guard currentFlatIndex < flattenedPhases.count else { return }

        let current = flattenedPhases[currentFlatIndex]
        let phaseElapsedTime = context.elapsedTime - phaseStartTime
        let phaseElapsedDistance = context.distanceKm - phaseStartDistance

        let shouldTransition: Bool
        switch current.phase.trigger {
        case .duration(let seconds):
            shouldTransition = phaseElapsedTime >= seconds
        case .distance(let km):
            shouldTransition = phaseElapsedDistance >= km
        }

        guard shouldTransition else { return }

        recordCompletedPhase(context: context)
        advanceToNextPhase(context: context)
    }

    func recordCompletedPhase(context: RunContext) {
        let current = flattenedPhases[currentFlatIndex]
        let distanceInPhase = context.distanceKm - phaseStartDistance
        let durationInPhase = context.elapsedTime - phaseStartTime

        let pace: Double
        if distanceInPhase > 0 {
            pace = durationInPhase / distanceInPhase
        } else {
            pace = 0
        }

        let avgHR: Int?
        if !heartRatesInPhase.isEmpty {
            avgHR = heartRatesInPhase.reduce(0, +) / heartRatesInPhase.count
        } else {
            avgHR = nil
        }

        let split = IntervalSplit(
            id: UUID(),
            phaseIndex: currentFlatIndex,
            phaseType: current.phase.phaseType,
            startTime: phaseStartTime,
            endTime: context.elapsedTime,
            distanceKm: distanceInPhase,
            averagePaceSecondsPerKm: pace,
            averageHeartRate: avgHR,
            maxHeartRate: heartRatesInPhase.max()
        )
        intervalSplits.append(split)
    }

    func advanceToNextPhase(context: RunContext) {
        let previousPhase = flattenedPhases[currentFlatIndex]
        currentFlatIndex += 1
        phaseStartTime = context.elapsedTime
        phaseStartDistance = context.distanceKm
        heartRatesInPhase = []

        if currentFlatIndex >= flattenedPhases.count {
            completeWorkout()
            return
        }

        let nextPhase = flattenedPhases[currentFlatIndex]

        let workIndex: Int?
        if nextPhase.phase.phaseType == .work {
            let workPhasesSoFar = flattenedPhases[0...currentFlatIndex]
                .filter { $0.phase.phaseType == .work }.count
            workIndex = workPhasesSoFar
        } else {
            workIndex = nil
        }

        let totalWork = flattenedPhases
            .filter { $0.phase.phaseType == .work }.count

        let transition = IntervalPhaseTransition(
            fromPhase: previousPhase.phase.phaseType,
            toPhase: nextPhase.phase.phaseType,
            message: buildTransitionMessage(
                from: previousPhase.phase.phaseType,
                to: nextPhase.phase.phaseType,
                intervalNumber: workIndex,
                totalIntervals: totalWork
            ),
            intervalNumber: workIndex,
            totalIntervals: totalWork
        )

        showPhaseTransitionBanner = transition
        scheduleBannerDismiss()

        if nextPhase.phase.phaseType == .work {
            hapticService.playIntervalStart()
        } else {
            hapticService.playIntervalEnd()
        }

        updateCurrentState(context: context)
        Logger.tracking.info("Interval phase transition: \(previousPhase.phase.phaseType.rawValue) → \(nextPhase.phase.phaseType.rawValue)")
    }

    func completeWorkout() {
        currentState = nil
        hapticService.playSuccess()
        Logger.tracking.info("Interval workout completed with \(self.intervalSplits.count) splits")
    }

    // MARK: - Banner

    func scheduleBannerDismiss() {
        bannerDismissTask?.cancel()
        bannerDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppConfiguration.IntervalGuidance.phaseTransitionBannerDismissSeconds))
            guard !Task.isCancelled else { return }
            self?.showPhaseTransitionBanner = nil
        }
    }

    // MARK: - Helpers

    func buildTransitionMessage(
        from: IntervalPhaseType,
        to: IntervalPhaseType,
        intervalNumber: Int?,
        totalIntervals: Int?
    ) -> String {
        switch to {
        case .warmUp:
            return "Warm up"
        case .work:
            if let num = intervalNumber, let total = totalIntervals {
                return "GO! Interval \(num) of \(total)"
            }
            return "GO!"
        case .recovery:
            return "Recover"
        case .coolDown:
            return "Cool down"
        }
    }
}
