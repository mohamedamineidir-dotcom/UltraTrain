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

    let hapticService: any HapticServiceProtocol
    let intervalWorkout: IntervalWorkout?

    // MARK: - Private

    var flattenedPhases: [(phase: IntervalPhase, repeatIndex: Int)] = []
    var currentFlatIndex: Int = 0
    var phaseStartTime: TimeInterval = 0
    var phaseStartDistance: Double = 0
    var heartRatesInPhase: [Int] = []
    var countdownTask: Task<Void, Never>?
    var bannerDismissTask: Task<Void, Never>?
    var workoutStarted = false

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

    func startWorkout(context: RunContext) {
        workoutStarted = true
        phaseStartTime = context.elapsedTime
        phaseStartDistance = context.distanceKm
        heartRatesInPhase = []
        updateCurrentState(context: context)
        hapticService.playIntervalStart()
        Logger.tracking.info("Interval workout started")
    }

    // MARK: - Private — State Update

    func updateCurrentState(context: RunContext) {
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

    // MARK: - Flatten Phases

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
