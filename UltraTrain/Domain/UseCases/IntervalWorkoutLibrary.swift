import Foundation

enum IntervalWorkoutLibrary {

    static let allWorkouts: [IntervalWorkout] = [
        fourByOneKm,
        sixByEightHundred,
        pyramid,
        trailFartlek,
        hillIntervals,
        thirtyThirty,
        tempoIntervals,
        threeByTwoKm
    ]

    // MARK: - 4x1km

    static let fourByOneKm = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000001")!,
        name: "4x1km Repeats",
        descriptionText: "Classic 1km repeats with 400m jog recovery. Great for building speed endurance.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0001-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0001-100000000002")!,
                          phaseType: .work, trigger: .distance(km: 1.0),
                          targetIntensity: .hard, repeatCount: 4),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0001-100000000003")!,
                          phaseType: .recovery, trigger: .distance(km: 0.4),
                          targetIntensity: .easy, repeatCount: 4),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0001-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .speedWork,
        estimatedDurationSeconds: 3600,
        estimatedDistanceKm: 9.0,
        isUserCreated: false
    )

    // MARK: - 6x800m

    static let sixByEightHundred = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000002")!,
        name: "6x800m VO2max",
        descriptionText: "800m repeats at near-max effort for VO2max development.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0002-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0002-100000000002")!,
                          phaseType: .work, trigger: .distance(km: 0.8),
                          targetIntensity: .maxEffort, repeatCount: 6),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0002-100000000003")!,
                          phaseType: .recovery, trigger: .duration(seconds: 120),
                          targetIntensity: .easy, repeatCount: 6),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0002-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .speedWork,
        estimatedDurationSeconds: 3000,
        estimatedDistanceKm: 8.0,
        isUserCreated: false
    )

    // MARK: - Pyramid

    static let pyramid = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000003")!,
        name: "Pyramid 1-2-3-2-1",
        descriptionText: "Ascending and descending work intervals with equal recovery. Builds mental toughness.",
        phases: buildPyramidPhases(),
        category: .speedWork,
        estimatedDurationSeconds: 3600,
        estimatedDistanceKm: 10.0,
        isUserCreated: false
    )

    // MARK: - Trail Fartlek

    static let trailFartlek = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000004")!,
        name: "Structured Trail Fartlek",
        descriptionText: "Alternating 3min hard and 2min easy. Perfect for trail running rhythm.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0004-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0004-100000000002")!,
                          phaseType: .work, trigger: .duration(seconds: 180),
                          targetIntensity: .hard, repeatCount: 8),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0004-100000000003")!,
                          phaseType: .recovery, trigger: .duration(seconds: 120),
                          targetIntensity: .easy, repeatCount: 8),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0004-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .trailSpecific,
        estimatedDurationSeconds: 3600,
        estimatedDistanceKm: 10.0,
        isUserCreated: false
    )

    // MARK: - Hill Intervals

    static let hillIntervals = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000005")!,
        name: "Hill Intervals 8x3min",
        descriptionText: "3-minute uphill efforts with jog-down recovery. Builds climbing strength.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0005-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0005-100000000002")!,
                          phaseType: .work, trigger: .duration(seconds: 180),
                          targetIntensity: .hard, repeatCount: 8),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0005-100000000003")!,
                          phaseType: .recovery, trigger: .duration(seconds: 180),
                          targetIntensity: .easy, repeatCount: 8),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0005-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .hillTraining,
        estimatedDurationSeconds: 4080,
        estimatedDistanceKm: 10.0,
        isUserCreated: false
    )

    // MARK: - 30/30s

    static let thirtyThirty = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000006")!,
        name: "30/30 Intervals",
        descriptionText: "20 rounds of 30s hard, 30s easy. High-frequency VO2max stimulus.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0006-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0006-100000000002")!,
                          phaseType: .work, trigger: .duration(seconds: 30),
                          targetIntensity: .maxEffort, repeatCount: 20),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0006-100000000003")!,
                          phaseType: .recovery, trigger: .duration(seconds: 30),
                          targetIntensity: .easy, repeatCount: 20),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0006-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .speedWork,
        estimatedDurationSeconds: 2400,
        estimatedDistanceKm: 7.0,
        isUserCreated: false
    )

    // MARK: - Tempo Intervals

    static let tempoIntervals = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000007")!,
        name: "2x10min Tempo",
        descriptionText: "Two 10-minute tempo efforts with 3-minute recovery. Builds lactate threshold.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0007-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0007-100000000002")!,
                          phaseType: .work, trigger: .duration(seconds: 600),
                          targetIntensity: .moderate, repeatCount: 2),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0007-100000000003")!,
                          phaseType: .recovery, trigger: .duration(seconds: 180),
                          targetIntensity: .easy, repeatCount: 2),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0007-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .speedWork,
        estimatedDurationSeconds: 2760,
        estimatedDistanceKm: 9.0,
        isUserCreated: false
    )

    // MARK: - 3x2km Threshold

    static let threeByTwoKm = IntervalWorkout(
        id: UUID(uuidString: "A0000001-0001-0001-0001-000000000008")!,
        name: "3x2km Threshold",
        descriptionText: "Long threshold repeats with 800m jog recovery. Race-specific fitness builder.",
        phases: [
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0008-100000000001")!,
                          phaseType: .warmUp, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0008-100000000002")!,
                          phaseType: .work, trigger: .distance(km: 2.0),
                          targetIntensity: .hard, repeatCount: 3),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0008-100000000003")!,
                          phaseType: .recovery, trigger: .distance(km: 0.8),
                          targetIntensity: .easy, repeatCount: 3),
            IntervalPhase(id: UUID(uuidString: "A0000001-0001-0001-0008-100000000004")!,
                          phaseType: .coolDown, trigger: .duration(seconds: 600),
                          targetIntensity: .easy, repeatCount: 1)
        ],
        category: .speedWork,
        estimatedDurationSeconds: 3600,
        estimatedDistanceKm: 12.0,
        isUserCreated: false
    )

    // MARK: - Helpers

    private static func buildPyramidPhases() -> [IntervalPhase] {
        let durations: [TimeInterval] = [60, 120, 180, 120, 60]
        var phases: [IntervalPhase] = []

        phases.append(IntervalPhase(
            id: UUID(uuidString: "A0000001-0001-0001-0003-100000000001")!,
            phaseType: .warmUp, trigger: .duration(seconds: 600),
            targetIntensity: .easy, repeatCount: 1
        ))

        for (index, duration) in durations.enumerated() {
            let workId = UUID(uuidString: "A0000001-0001-0001-0003-10000000000\(index + 2)")!
            phases.append(IntervalPhase(
                id: workId,
                phaseType: .work, trigger: .duration(seconds: duration),
                targetIntensity: .hard, repeatCount: 1
            ))

            if index < durations.count - 1 {
                let recoveryId = UUID(uuidString: "A0000001-0001-0001-0003-20000000000\(index + 1)")!
                phases.append(IntervalPhase(
                    id: recoveryId,
                    phaseType: .recovery, trigger: .duration(seconds: duration),
                    targetIntensity: .easy, repeatCount: 1
                ))
            }
        }

        phases.append(IntervalPhase(
            id: UUID(uuidString: "A0000001-0001-0001-0003-100000000099")!,
            phaseType: .coolDown, trigger: .duration(seconds: 600),
            targetIntensity: .easy, repeatCount: 1
        ))

        return phases
    }
}
