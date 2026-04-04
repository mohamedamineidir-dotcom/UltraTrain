import Foundation

/// Generates strength & conditioning sessions based on athlete profile,
/// training phase, injury history, and preferences.
///
/// Based on research from Jason Koop (CTS), David Roche (SWAP),
/// Uphill Athlete, and sports science literature.
enum StrengthSessionGenerator {

    // MARK: - Configuration

    struct Config: Sendable {
        let experience: ExperienceLevel
        let phase: TrainingPhase
        let location: StrengthTrainingLocation
        let painFrequency: PainFrequency
        let injuryCount: InjuryCount
        let hasRecentInjury: Bool
        let preferredRunsPerWeek: Int
        let weekNumberInPhase: Int
        let isRecoveryWeek: Bool
        let raceEffectiveKm: Double
    }

    // MARK: - Public API

    /// Returns the number of S&C sessions for this week.
    static func sessionsPerWeek(config: Config) -> Int {
        let base: Int
        switch config.experience {
        case .beginner:     base = 2
        case .intermediate: base = 2
        case .advanced:     base = 3
        case .elite:        base = 2
        }

        let phaseAdjusted: Int
        switch config.phase {
        case .base:
            phaseAdjusted = base
        case .build:
            phaseAdjusted = min(base, 2)
        case .peak:
            phaseAdjusted = min(base, 2)
        case .taper:
            phaseAdjusted = config.experience == .beginner ? 0 : 1
        case .recovery:
            phaseAdjusted = 1
        case .race:
            phaseAdjusted = 0
        }

        // Recovery weeks: max 1 session
        if config.isRecoveryWeek {
            return min(phaseAdjusted, 1)
        }

        // If athlete runs 6-7 days, reduce S&C to avoid overload
        if config.preferredRunsPerWeek >= 6 {
            return min(phaseAdjusted, 1)
        }

        return phaseAdjusted
    }

    /// Generates a strength workout for a given session slot.
    /// - Parameter sessionIndex: 0-based index (0 = primary, 1 = secondary, 2 = tertiary)
    static func generateWorkout(
        config: Config,
        sessionIndex: Int
    ) -> StrengthWorkout {
        let category = categoryForSession(config: config, sessionIndex: sessionIndex)
        let exercises = selectExercises(config: config, category: category)
        let duration = estimatedDuration(category: category, exercises: exercises, phase: config.phase)

        let name = workoutName(config: config, category: category, sessionIndex: sessionIndex)

        return StrengthWorkout(
            name: name,
            category: category,
            exercises: exercises,
            estimatedDurationMinutes: duration
        )
    }

    /// Returns the day offsets (0=Mon..6=Sun) where S&C can be placed.
    /// Rules: Never on long run, intervals, or VG days.
    static func availableDayOffsets(
        runningSessions: [SessionTemplateGenerator.SessionTemplate],
        config: Config
    ) -> [Int] {
        let blockedDays = Set(
            runningSessions
                .filter { isHighStressSession($0.type) }
                .map { $0.dayOffset }
        )

        let allDays = Set(0...6)
        let available = allDays.subtracting(blockedDays)
        return Array(available).sorted()
    }

    // MARK: - Session Category

    private static func categoryForSession(
        config: Config,
        sessionIndex: Int
    ) -> StrengthSessionCategory {
        switch config.phase {
        case .taper:
            return .activation
        case .recovery:
            return .activation
        default:
            break
        }

        if config.isRecoveryWeek {
            return .activation
        }

        // Primary session is full, secondary/tertiary is maintenance
        switch sessionIndex {
        case 0:
            return config.phase == .peak ? .maintenance : .full
        default:
            return .maintenance
        }
    }

    // MARK: - Exercise Selection

    private static func selectExercises(
        config: Config,
        category: StrengthSessionCategory
    ) -> [StrengthExercise] {
        let isGym = config.location == .gym
        var exercises: [StrengthExercise] = []

        switch category {
        case .full:
            exercises += selectLowerBody(isGym: isGym, config: config)
            exercises += selectCore(isGym: isGym, config: config)
            exercises += selectSingleLeg(isGym: isGym, config: config)
            if config.phase == .build || config.phase == .peak {
                exercises += selectPlyometrics(config: config)
            }
            exercises += selectUpperBody(isGym: isGym, config: config)

        case .maintenance:
            exercises += selectCore(isGym: isGym, config: config)
            exercises += selectLowerBody(isGym: isGym, config: config).prefix(2)
            exercises += selectSingleLeg(isGym: isGym, config: config).prefix(1)

        case .activation:
            exercises += selectActivation(isGym: isGym)
        }

        // Add injury prevention exercises if applicable
        if config.hasRecentInjury || config.painFrequency == .often || config.painFrequency == .sometimes {
            let rehabExercises = selectInjuryPrevention(isGym: isGym, config: config)
            exercises += rehabExercises
        }

        return exercises
    }

    // MARK: - Exercise Library: Lower Body

    private static func selectLowerBody(isGym: Bool, config: Config) -> [StrengthExercise] {
        let sets: Int
        let reps: String
        switch config.phase {
        case .base:
            sets = config.experience == .beginner ? 2 : 3
            reps = config.experience == .beginner ? "12-15" : "10-12"
        case .build:
            sets = config.experience == .beginner ? 3 : 4
            reps = "6-8"
        case .peak:
            sets = 2
            reps = "6-8"
        default:
            sets = config.experience == .beginner ? 2 : 3
            reps = "10-12"
        }

        if isGym {
            return [
                StrengthExercise(
                    name: "Back Squat",
                    category: .lowerBody, sets: sets, reps: reps,
                    notes: "Control the descent. Knees track over toes.",
                    requiresEquipment: true
                ),
                StrengthExercise(
                    name: "Romanian Deadlift",
                    category: .lowerBody, sets: sets, reps: "8-10",
                    notes: "Hinge at hips, soft knees. Feel the hamstring stretch.",
                    requiresEquipment: true
                ),
                StrengthExercise(
                    name: "Hip Thrust",
                    category: .lowerBody, sets: sets, reps: "10-12",
                    notes: "Squeeze glutes at the top. Pause 1 second.",
                    requiresEquipment: true
                ),
            ]
        } else {
            return [
                StrengthExercise(
                    name: "Goblet Squat",
                    category: .lowerBody, sets: sets, reps: reps,
                    notes: "Hold any weight at chest level, or bodyweight. Full depth."
                ),
                StrengthExercise(
                    name: "Single-Leg Romanian Deadlift",
                    category: .lowerBody, sets: sets, reps: "8-10 per side",
                    notes: "Keep hips level. Touch floor if flexible enough."
                ),
                StrengthExercise(
                    name: "Glute Bridge",
                    category: .lowerBody, sets: sets, reps: "12-15",
                    notes: "Drive through heels. Squeeze glutes at top for 2 seconds."
                ),
            ]
        }
    }

    // MARK: - Exercise Library: Core

    private static func selectCore(isGym: Bool, config: Config) -> [StrengthExercise] {
        let sets = config.experience == .beginner ? 2 : 3
        var exercises: [StrengthExercise] = [
            StrengthExercise(
                name: "Dead Bug",
                category: .core, sets: sets, reps: "8-10 per side",
                notes: "Press lower back into floor. Slow and controlled."
            ),
            StrengthExercise(
                name: "Side Plank",
                category: .core, sets: sets, reps: "20-30 sec per side",
                notes: "Stack hips. Keep body in a straight line."
            ),
        ]

        if isGym {
            exercises.append(StrengthExercise(
                name: "Pallof Press",
                category: .core, sets: sets, reps: "10 per side",
                notes: "Anti-rotation. Press cable away from chest, hold 2 sec.",
                requiresEquipment: true
            ))
        } else {
            exercises.append(StrengthExercise(
                name: "Bird Dog",
                category: .core, sets: sets, reps: "10 per side",
                notes: "Extend opposite arm and leg. Hold 2 seconds at full extension."
            ))
        }

        return exercises
    }

    // MARK: - Exercise Library: Single-Leg Stability

    private static func selectSingleLeg(isGym: Bool, config: Config) -> [StrengthExercise] {
        let sets = config.experience == .beginner ? 2 : 3

        if isGym {
            return [
                StrengthExercise(
                    name: "Bulgarian Split Squat",
                    category: .singleLegStability, sets: sets, reps: "8-10 per leg",
                    notes: "Rear foot on bench. Keep front knee over ankle.",
                    requiresEquipment: true
                ),
                StrengthExercise(
                    name: "Box Step-Up",
                    category: .singleLegStability, sets: sets, reps: "10 per leg",
                    notes: "Drive through the heel. Mimics uphill running.",
                    requiresEquipment: true
                ),
            ]
        } else {
            return [
                StrengthExercise(
                    name: "Bulgarian Split Squat",
                    category: .singleLegStability, sets: sets, reps: "8-10 per leg",
                    notes: "Rear foot on a couch or chair. Control the descent."
                ),
                StrengthExercise(
                    name: "Single-Leg Balance",
                    category: .singleLegStability, sets: sets, reps: "30 sec per leg",
                    notes: "Eyes open first. Progress to eyes closed when stable."
                ),
            ]
        }
    }

    // MARK: - Exercise Library: Plyometrics

    private static func selectPlyometrics(config: Config) -> [StrengthExercise] {
        // No plyometrics for beginners or recently injured athletes
        if config.experience == .beginner { return [] }
        if config.hasRecentInjury { return [] }

        let sets = config.phase == .peak ? 2 : 3

        if config.phase == .build {
            return [
                StrengthExercise(
                    name: "Squat Jumps",
                    category: .plyometric, sets: sets, reps: "8-10",
                    notes: "Land softly. Full squat depth before jumping."
                ),
                StrengthExercise(
                    name: "Lateral Bounds",
                    category: .plyometric, sets: sets, reps: "8 per side",
                    notes: "Stick the landing on one foot. Critical for trail terrain changes."
                ),
            ]
        } else {
            // Peak: reduced plyometrics
            return [
                StrengthExercise(
                    name: "Pogo Hops",
                    category: .plyometric, sets: 2, reps: "15-20",
                    notes: "Quick ground contact. Stiff ankles. Minimal knee bend."
                ),
            ]
        }
    }

    // MARK: - Exercise Library: Upper Body

    private static func selectUpperBody(isGym: Bool, config: Config) -> [StrengthExercise] {
        let sets = config.experience == .beginner ? 2 : 3

        if isGym {
            return [
                StrengthExercise(
                    name: "Bent Over Row",
                    category: .upperBody, sets: sets, reps: "8-10",
                    notes: "Squeeze shoulder blades together. Posture maintenance for long efforts.",
                    requiresEquipment: true
                ),
            ]
        } else {
            return [
                StrengthExercise(
                    name: "Push-Ups",
                    category: .upperBody, sets: sets, reps: "10-15",
                    notes: "Full range of motion. Modify on knees if needed."
                ),
            ]
        }
    }

    // MARK: - Exercise Library: Activation

    private static func selectActivation(isGym: Bool) -> [StrengthExercise] {
        [
            StrengthExercise(
                name: "Glute Bridge",
                category: .lowerBody, sets: 2, reps: "12",
                notes: "Activate glutes before running or as standalone."
            ),
            StrengthExercise(
                name: "Clamshell",
                category: .injuryPrevention, sets: 2, reps: "12 per side",
                notes: "Keep feet together. Feel the burn in outer hip."
            ),
            StrengthExercise(
                name: "Dead Bug",
                category: .core, sets: 2, reps: "8 per side",
                notes: "Gentle core activation. Keep lower back flat."
            ),
            StrengthExercise(
                name: "Walking Lunge",
                category: .lowerBody, sets: 2, reps: "8 per leg",
                notes: "Slow and controlled. Feel the stretch in hip flexors."
            ),
        ]
    }

    // MARK: - Injury Prevention Exercises

    private static func selectInjuryPrevention(isGym: Bool, config: Config) -> [StrengthExercise] {
        var exercises: [StrengthExercise] = []
        let sets = 3

        // Common runner rehab exercises
        exercises.append(StrengthExercise(
            name: "Clamshell with Band",
            category: .injuryPrevention, sets: sets, reps: "12-15 per side",
            notes: "Glute medius activation. Prevents IT band issues and knee pain."
        ))

        exercises.append(StrengthExercise(
            name: "Eccentric Calf Raise",
            category: .injuryPrevention, sets: sets, reps: "12-15",
            notes: "3 sec lowering phase. Both straight and bent knee versions. Achilles and calf health."
        ))

        if config.painFrequency == .often || config.hasRecentInjury {
            exercises.append(StrengthExercise(
                name: "Hip Hike on Step",
                category: .injuryPrevention, sets: sets, reps: "12 per side",
                notes: "Stand on step edge. Lower hip then raise. Strengthens glute medius and hip stabilizers."
            ))

            exercises.append(StrengthExercise(
                name: "Ankle Stability - Star Reach",
                category: .injuryPrevention, sets: 2, reps: "3 rounds per leg",
                notes: "Stand on one leg, reach other foot in 4 directions. Ankle proprioception for trails."
            ))
        }

        // For ultra trail: extra ankle and quad eccentric work
        if config.raceEffectiveKm > 50 {
            exercises.append(StrengthExercise(
                name: "Single-Leg Balance (Eyes Closed)",
                category: .injuryPrevention, sets: 2, reps: "15-20 sec per leg",
                notes: "Advanced proprioception. Essential for technical trail terrain."
            ))
        }

        return exercises
    }

    // MARK: - Helpers

    private static func isHighStressSession(_ type: SessionType) -> Bool {
        switch type {
        case .longRun, .backToBack, .intervals, .verticalGain:
            return true
        default:
            return false
        }
    }

    /// Calculates realistic duration based on exercise count, sets, rest periods, and phase.
    /// Warmup 5min + exercises (sets x ~35sec work + rest + 30sec transition) + cooldown 5min.
    /// Rest varies by phase: base 60s, build 90-120s, peak 60-90s.
    static func estimatedDuration(
        category: StrengthSessionCategory,
        exercises: [StrengthExercise],
        phase: TrainingPhase = .base
    ) -> Int {
        let warmupCooldown = 10 // 5 + 5

        let restBetweenSets: Double
        switch category {
        case .full:
            switch phase {
            case .base: restBetweenSets = 60
            case .build: restBetweenSets = 105 // heavier loads need more recovery
            case .peak: restBetweenSets = 75
            default: restBetweenSets = 60
            }
        case .maintenance: restBetweenSets = 60
        case .activation: restBetweenSets = 30
        }

        var workingBlockSeconds: Double = 0
        for ex in exercises {
            let workPerSet: Double = 35
            let sets = Double(ex.sets)
            let restPeriods = max(sets - 1, 0)
            let transitionTime: Double = 30
            workingBlockSeconds += (sets * workPerSet) + (restPeriods * restBetweenSets) + transitionTime
        }

        let totalMinutes = warmupCooldown + Int((workingBlockSeconds / 60).rounded())
        return max(totalMinutes, 15)
    }

    private static func workoutName(
        config: Config,
        category: StrengthSessionCategory,
        sessionIndex: Int
    ) -> String {
        let phaseName: String
        switch config.phase {
        case .base: phaseName = "Foundation"
        case .build: phaseName = "Strength-Power"
        case .peak: phaseName = "Maintenance"
        case .taper: phaseName = "Activation"
        case .recovery: phaseName = "Recovery"
        case .race: phaseName = "Pre-Race"
        }

        let locationSuffix = config.location == .gym ? "Gym" : "Home"

        switch category {
        case .full:
            return "\(phaseName) S&C (\(locationSuffix))"
        case .maintenance:
            return "\(phaseName) Quick S&C (\(locationSuffix))"
        case .activation:
            return "Activation & Mobility"
        }
    }
}
