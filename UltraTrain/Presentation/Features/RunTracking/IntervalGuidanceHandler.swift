import Foundation
import os

@Observable
@MainActor
final class IntervalGuidanceHandler {

    // MARK: - State

    var currentState: IntervalWorkoutState?
    var intervalSplits: [IntervalSplit] = []
    var showPhaseTransitionBanner: IntervalPhaseTransition?
    var isCountingDown: Bool = false
    var countdownSeconds: Int = 0

    var isActive: Bool { intervalWorkout != nil }

    // MARK: - Dependencies

    private let hapticService: any HapticServiceProtocol
    private let intervalWorkout: IntervalWorkout?

    // MARK: - Private

    private var flattenedPhases: [(phase: IntervalPhase, repeatIndex: Int)] = []
    private var currentFlatIndex: Int = 0
    private var phaseStartTime: TimeInterval = 0
    private var phaseStartDistance: Double = 0
    private var heartRatesInPhase: [Int] = []
    private var countdownTask: Task<Void, Never>?
    private var bannerDismissTask: Task<Void, Never>?
    private var workoutStarted = false

    // MARK: - Context

    struct RunContext: Sendable {
        let elapsedTime: TimeInterval
        let distanceKm: Double
        let currentHeartRate: Int?
        let currentPace: Double
    }

    // MARK: - Init

    init(hapticService: any HapticServiceProtocol, intervalWorkout: IntervalWorkout?) {
        self.hapticService = hapticService
        self.intervalWorkout = intervalWorkout
        if let workout = intervalWorkout {
            self.flattenedPhases = Self.flattenPhases(workout.phases)
        }
    }

    // MARK: - Tick

    func tick(context: RunContext) {
        guard isActive, !flattenedPhases.isEmpty else { return }

        if !workoutStarted {
            startWorkout(context: context)
            return
        }

        guard currentFlatIndex < flattenedPhases.count else { return }

        if let hr = context.currentHeartRate {
            heartRatesInPhase.append(hr)
        }

        updateCurrentState(context: context)
        checkPhaseTransition(context: context)
    }

    // MARK: - Private — Workout Start

    private func startWorkout(context: RunContext) {
        workoutStarted = true
        phaseStartTime = context.elapsedTime
        phaseStartDistance = context.distanceKm
        heartRatesInPhase = []
        updateCurrentState(context: context)
        hapticService.playIntervalStart()
        Logger.tracking.info("Interval workout started")
    }

    // MARK: - Private — State Update

    private func updateCurrentState(context: RunContext) {
        guard currentFlatIndex < flattenedPhases.count else {
            currentState = nil
            return
        }

        let current = flattenedPhases[currentFlatIndex]
        let phaseElapsedTime = context.elapsedTime - phaseStartTime
        let phaseElapsedDistance = context.distanceKm - phaseStartDistance

        let remainingTime: TimeInterval?
        let remainingDistance: Double?

        switch current.phase.trigger {
        case .duration(let seconds):
            remainingTime = max(0, seconds - phaseElapsedTime)
            remainingDistance = nil
        case .distance(let km):
            remainingTime = nil
            remainingDistance = max(0, km - phaseElapsedDistance)
        }

        let workPhasesSoFar = flattenedPhases[0..<currentFlatIndex]
            .filter { $0.phase.phaseType == .work }.count
        let totalWorkPhases = flattenedPhases
            .filter { $0.phase.phaseType == .work }.count

        let progress: Double
        if flattenedPhases.count > 1 {
            progress = Double(currentFlatIndex) / Double(flattenedPhases.count - 1)
        } else {
            progress = currentFlatIndex >= flattenedPhases.count ? 1.0 : 0.0
        }

        currentState = IntervalWorkoutState(
            currentPhaseIndex: currentFlatIndex,
            currentPhaseType: current.phase.phaseType,
            currentRepeat: current.repeatIndex + 1,
            totalRepeats: current.phase.repeatCount,
            phaseElapsedTime: phaseElapsedTime,
            phaseElapsedDistance: phaseElapsedDistance,
            phaseRemainingTime: remainingTime,
            phaseRemainingDistance: remainingDistance,
            isLastPhase: currentFlatIndex == flattenedPhases.count - 1,
            completedPhases: currentFlatIndex,
            totalPhases: flattenedPhases.count,
            overallProgress: min(1.0, progress),
            targetIntensity: current.phase.targetIntensity
        )
    }

    // MARK: - Private — Phase Transition

    private func checkPhaseTransition(context: RunContext) {
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

    private func recordCompletedPhase(context: RunContext) {
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

    private func advanceToNextPhase(context: RunContext) {
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
            let totalWork = flattenedPhases
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

    private func completeWorkout() {
        currentState = nil
        hapticService.playSuccess()
        Logger.tracking.info("Interval workout completed with \(self.intervalSplits.count) splits")
    }

    // MARK: - Private — Banner

    private func scheduleBannerDismiss() {
        bannerDismissTask?.cancel()
        bannerDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(AppConfiguration.IntervalGuidance.phaseTransitionBannerDismissSeconds))
            guard !Task.isCancelled else { return }
            self?.showPhaseTransitionBanner = nil
        }
    }

    // MARK: - Private — Helpers

    private func buildTransitionMessage(
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

    static func flattenPhases(_ phases: [IntervalPhase]) -> [(phase: IntervalPhase, repeatIndex: Int)] {
        var result: [(phase: IntervalPhase, repeatIndex: Int)] = []
        var index = 0

        while index < phases.count {
            let phase = phases[index]

            if phase.phaseType == .work,
               index + 1 < phases.count,
               phases[index + 1].phaseType == .recovery {
                let recovery = phases[index + 1]
                let reps = phase.repeatCount
                for i in 0..<reps {
                    result.append((phase: phase, repeatIndex: i))
                    if i < reps - 1 {
                        result.append((phase: recovery, repeatIndex: i))
                    }
                }
                index += 2
            } else {
                for i in 0..<phase.repeatCount {
                    result.append((phase: phase, repeatIndex: i))
                }
                index += 1
            }
        }

        return result
    }
}
