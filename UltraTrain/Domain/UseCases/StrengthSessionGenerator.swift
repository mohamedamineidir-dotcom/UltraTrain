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
        /// T13: race format drives discipline-specific exercise pools
        /// for plyometrics + injury prevention. Road runners get
        /// elastic-stiffness + hip-stability emphasis; trail/ultra
        /// runners get eccentric quad + ankle proprioception. Defaults
        /// to .trail to preserve existing behavior for older callers.
        let raceType: RaceType
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
            estimatedDurationMinutes: duration,
            warmUpNotes: "",
            coolDownNotes: ""
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
        let hasInjuryConcern = config.hasRecentInjury || config.painFrequency == .often || config.painFrequency == .sometimes

        switch category {
        case .full:
            // Target: 5-6 exercises total for ~40-50min session
            // Structure: 2 compound lower + 1 single-leg + 1 core + 1 plyo or upper
            // If injury concern: swap 1 slot for injury prevention
            var exercises: [StrengthExercise] = []
            exercises += selectLowerBody(isGym: isGym, config: config).prefix(2)
            exercises += selectSingleLeg(isGym: isGym, config: config).prefix(1)
            exercises += selectCore(isGym: isGym, config: config).prefix(1)

            if hasInjuryConcern {
                exercises += selectInjuryPrevention(isGym: isGym, config: config).prefix(2)
            } else if config.phase == .build || config.phase == .peak {
                exercises += selectPlyometrics(config: config).prefix(1)
                exercises += selectUpperBody(isGym: isGym, config: config).prefix(1)
            } else {
                exercises += selectUpperBody(isGym: isGym, config: config).prefix(1)
                exercises += selectCore(isGym: isGym, config: config).suffix(1)
            }
            return Array(exercises.prefix(6))

        case .maintenance:
            // Target: 4-5 exercises for ~30-35min session
            var exercises: [StrengthExercise] = []
            exercises += selectLowerBody(isGym: isGym, config: config).prefix(2)
            exercises += selectSingleLeg(isGym: isGym, config: config).prefix(1)
            exercises += selectCore(isGym: isGym, config: config).prefix(1)
            if hasInjuryConcern {
                exercises += selectInjuryPrevention(isGym: isGym, config: config).prefix(1)
            } else {
                exercises += selectUpperBody(isGym: isGym, config: config).prefix(1)
            }
            return Array(exercises.prefix(5))

        case .activation:
            return selectActivation(isGym: isGym)
        }
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

        // Phase-rotated exercise selection. Pool indices have specific
        // training emphases:
        //   0 = compound squat-focused (heaviest force production)
        //   1 = hinge-focused (posterior chain, structural strength)
        //   2 = unilateral-focused (stability, anatomical adaptation)
        //
        // Phase mapping:
        //   .base   → rotate freely through all 3 patterns (anatomical
        //             adaptation period, variety builds movement
        //             vocabulary + tendon/ligament tolerance)
        //   .build  → alternate squat (0) and hinge (1) only, strength
        //             + power phase, drop the unilateral-focused
        //             pattern that's better suited to base
        //   .peak   → lock to squat pattern (0), maintenance phase,
        //             athlete doesn't need to learn new movements while
        //             also peaking aerobic load. Single familiar
        //             pattern, lower volume (handled by sets reduction)
        //   default → freely rotate (covers .recovery / unknown phases)
        let weekVariation = config.weekNumberInPhase
        let phaseAdjustedIndex: Int
        switch config.phase {
        case .base:    phaseAdjustedIndex = weekVariation
        case .build:   phaseAdjustedIndex = weekVariation % 2
        case .peak:    phaseAdjustedIndex = 0
        default:       phaseAdjustedIndex = weekVariation
        }

        if isGym {
            let pool: [[StrengthExercise]] = [
                // Week A pattern: squat-focused
                [
                    StrengthExercise(name: "Back Squat", category: .lowerBody, sets: sets, reps: reps,
                                    notes: String(localized: "str.note.backSquat", defaultValue: "Control the descent. Knees track over toes."), requiresEquipment: true),
                    StrengthExercise(name: String(localized: "str.name.rdl", defaultValue: "Romanian Deadlift"), category: .lowerBody, sets: sets, reps: "8-10",
                                    notes: String(localized: "str.note.rdl", defaultValue: "Hinge at hips, soft knees. Feel the hamstring stretch."), requiresEquipment: true),
                ],
                // Week B pattern: hinge-focused
                [
                    StrengthExercise(name: String(localized: "str.name.hexDeadlift", defaultValue: "Hex Bar Deadlift"), category: .lowerBody, sets: sets, reps: reps,
                                    notes: String(localized: "str.note.hexDeadlift", defaultValue: "Drive through your whole foot. Keep chest up."), requiresEquipment: true),
                    StrengthExercise(name: "Hip Thrust", category: .lowerBody, sets: sets, reps: "10-12",
                                    notes: String(localized: "str.note.hipThrust", defaultValue: "Squeeze glutes at the top. Pause 1 second."), requiresEquipment: true),
                ],
                // Week C pattern: unilateral-focused
                [
                    StrengthExercise(name: "Front Squat", category: .lowerBody, sets: sets, reps: reps,
                                    notes: String(localized: "str.note.frontSquat", defaultValue: "Elbows high, core tight. Builds upright climbing posture."), requiresEquipment: true),
                    StrengthExercise(name: String(localized: "str.name.walkingLunges", defaultValue: "Walking Lunges"), category: .lowerBody, sets: sets, reps: String(localized: "str.reps.10leg", defaultValue: "10 per leg"),
                                    notes: String(localized: "str.note.walkingLunges", defaultValue: "Long stride, controlled descent. Mimics uphill stride pattern."), requiresEquipment: true),
                ],
            ]
            return pool[phaseAdjustedIndex % pool.count]
        } else {
            let pool: [[StrengthExercise]] = [
                [
                    StrengthExercise(name: "Goblet Squat", category: .lowerBody, sets: sets, reps: reps,
                                    notes: String(localized: "str.note.gobletSquat", defaultValue: "Hold any weight at chest level, or bodyweight. Full depth.")),
                    StrengthExercise(name: String(localized: "str.name.slRdl", defaultValue: "Single-Leg Romanian Deadlift"), category: .lowerBody, sets: sets, reps: String(localized: "str.reps.810side", defaultValue: "8-10 per side"),
                                    notes: String(localized: "str.note.slRdl", defaultValue: "Keep hips level. Touch floor if flexible enough.")),
                ],
                [
                    StrengthExercise(name: String(localized: "str.name.reverseLunge", defaultValue: "Reverse Lunge"), category: .lowerBody, sets: sets, reps: String(localized: "str.reps.10leg", defaultValue: "10 per leg"),
                                    notes: String(localized: "str.note.reverseLunge", defaultValue: "Step back, lower with control. Drive through front heel.")),
                    StrengthExercise(name: String(localized: "str.name.gluteBridge", defaultValue: "Glute Bridge"), category: .lowerBody, sets: sets, reps: "12-15",
                                    notes: String(localized: "str.note.gluteBridge2s", defaultValue: "Drive through heels. Squeeze glutes at top for 2 seconds.")),
                ],
                [
                    StrengthExercise(name: "Step-Up", category: .lowerBody, sets: sets, reps: String(localized: "str.reps.10leg", defaultValue: "10 per leg"),
                                    notes: String(localized: "str.note.stepUpLeg", defaultValue: "Step onto a sturdy box or stair, drive through the top leg, lower with control. Builds the climbing strength trails demand.")),
                    StrengthExercise(name: String(localized: "str.name.slHipThrust", defaultValue: "Single-Leg Hip Thrust"), category: .lowerBody, sets: sets, reps: String(localized: "str.reps.10side", defaultValue: "10 per side"),
                                    notes: String(localized: "str.note.slHipThrust", defaultValue: "One leg planted, other extended. Max glute activation.")),
                ],
            ]
            return pool[phaseAdjustedIndex % pool.count]
        }
    }

    // MARK: - Exercise Library: Core

    private static func selectCore(isGym: Bool, config: Config) -> [StrengthExercise] {
        let sets = config.experience == .beginner ? 2 : 3
        let weekVariation = config.weekNumberInPhase

        // Rotate core exercises for variety
        let corePool: [(String, String, String)] = [
            ("Bicycle Crunch", String(localized: "str.reps.1215side", defaultValue: "12-15 per side"), String(localized: "str.note.bicycleCrunch", defaultValue: "Bring your opposite elbow toward your knee, slow and controlled. Keep your lower back on the floor.")),
            (String(localized: "str.name.sidePlank", defaultValue: "Side Plank"), String(localized: "str.reps.2030secSide", defaultValue: "20-30 sec per side"), String(localized: "str.note.sidePlankCore", defaultValue: "Stack hips. Keep body in a straight line.")),
            ("Bird Dog", String(localized: "str.reps.10side", defaultValue: "10 per side"), String(localized: "str.note.birdDog", defaultValue: "Extend opposite arm and leg. Hold 2 seconds at full extension.")),
            ("Plank Shoulder Tap", String(localized: "str.reps.810side", defaultValue: "8-10 per side"), String(localized: "str.note.plankTap", defaultValue: "Stay stable through the hips. No rotation.")),
        ]

        let startIdx = weekVariation % corePool.count
        var exercises: [StrengthExercise] = [
            StrengthExercise(name: corePool[startIdx].0, category: .core, sets: sets,
                            reps: corePool[startIdx].1, notes: corePool[startIdx].2),
        ]

        if isGym {
            let gymCore = weekVariation % 2 == 0
                ? StrengthExercise(name: "Russian Twist", category: .core, sets: sets, reps: String(localized: "str.reps.10side", defaultValue: "10 per side"),
                                  notes: String(localized: "str.note.russianTwist", defaultValue: "Sit back slightly and rotate your torso side to side under control. Trains the rotational core that keeps you steady on uneven ground."))
                : StrengthExercise(name: "Cable Woodchop", category: .core, sets: sets, reps: String(localized: "str.reps.10side", defaultValue: "10 per side"),
                                  notes: String(localized: "str.note.woodchop", defaultValue: "Rotate from the hips, not the shoulders. Control the return."), requiresEquipment: true)
            exercises.append(gymCore)
        } else {
            let nextIdx = (startIdx + 1) % corePool.count
            exercises.append(StrengthExercise(name: corePool[nextIdx].0, category: .core, sets: sets,
                                            reps: corePool[nextIdx].1, notes: corePool[nextIdx].2))
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
                    category: .singleLegStability, sets: sets, reps: String(localized: "str.reps.810leg", defaultValue: "8-10 per leg"),
                    notes: String(localized: "str.note.bulgarianGym", defaultValue: "Rear foot on bench. Keep front knee over ankle."),
                    requiresEquipment: true
                ),
                StrengthExercise(
                    name: "Box Step-Up",
                    category: .singleLegStability, sets: sets, reps: String(localized: "str.reps.10leg", defaultValue: "10 per leg"),
                    notes: String(localized: "str.note.boxStepUp", defaultValue: "Drive through the heel. Mimics uphill running."),
                    requiresEquipment: true
                ),
            ]
        } else {
            return [
                StrengthExercise(
                    name: "Bulgarian Split Squat",
                    category: .singleLegStability, sets: sets, reps: String(localized: "str.reps.810leg", defaultValue: "8-10 per leg"),
                    notes: String(localized: "str.note.bulgarianHome", defaultValue: "Rear foot on a couch or chair. Control the descent.")
                ),
                StrengthExercise(
                    name: String(localized: "str.name.slBalance", defaultValue: "Single-Leg Balance"),
                    category: .singleLegStability, sets: sets, reps: String(localized: "str.reps.30secLeg", defaultValue: "30 sec per leg"),
                    notes: String(localized: "str.note.slBalance", defaultValue: "Eyes open first. Progress to eyes closed when stable.")
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

        // T13: discipline-specific plyometric pools.
        //
        // ROAD (Blagrove 2018 meta-analysis; Paavolainen 1999): elastic
        // stiffness + reactive ground contact drive running economy.
        // Pogo hops + low box jumps + ankle pogos are the keystone.
        //
        // TRAIL (House/Johnston; Roche): lateral stability for terrain
        // changes + landing absorption. Lateral bounds + squat jumps
        // with controlled landing.
        switch config.raceType {
        case .road:
            if config.phase == .build {
                return [
                    StrengthExercise(
                        name: "Pogo Hops",
                        category: .plyometric, sets: sets, reps: "20-30",
                        notes: String(localized: "str.note.pogoBuild", defaultValue: "Quick ground contact. Stiff ankles, minimal knee bend. Builds tendon stiffness, strongly correlated with running economy.")
                    ),
                    StrengthExercise(
                        name: "Low Box Jumps",
                        category: .plyometric, sets: sets, reps: "5-6",
                        notes: String(localized: "str.note.lowBox", defaultValue: "30-45 cm box. Soft landing, full recovery between reps. Reactive strength, not a max test.")
                    ),
                ]
            } else {
                // Peak road: maintain elastic stiffness, dose lower
                return [
                    StrengthExercise(
                        name: "Pogo Hops",
                        category: .plyometric, sets: 2, reps: "15-20",
                        notes: String(localized: "str.note.pogoPeak", defaultValue: "Quick ground contact. Stiff ankles. Maintain tendon stiffness through peak.")
                    ),
                ]
            }
        case .trail:
            if config.phase == .build {
                return [
                    StrengthExercise(
                        name: "Squat Jumps",
                        category: .plyometric, sets: sets, reps: "8-10",
                        notes: String(localized: "str.note.squatJumps", defaultValue: "Land softly. Full squat depth before jumping.")
                    ),
                    StrengthExercise(
                        name: "Lateral Bounds",
                        category: .plyometric, sets: sets, reps: String(localized: "str.reps.8side", defaultValue: "8 per side"),
                        notes: String(localized: "str.note.lateralBounds", defaultValue: "Stick the landing on one foot. Critical for trail terrain changes.")
                    ),
                ]
            } else {
                // Peak trail: reduced plyometrics
                return [
                    StrengthExercise(
                        name: "Pogo Hops",
                        category: .plyometric, sets: 2, reps: "15-20",
                        notes: String(localized: "str.note.pogoPeakTrail", defaultValue: "Quick ground contact. Stiff ankles. Minimal knee bend.")
                    ),
                ]
            }
        }
    }

    // MARK: - Exercise Library: Upper Body

    private static func selectUpperBody(isGym: Bool, config: Config) -> [StrengthExercise] {
        let sets = config.experience == .beginner ? 2 : 3

        if isGym {
            return [
                StrengthExercise(
                    name: String(localized: "str.name.row", defaultValue: "Bent Over Row"),
                    category: .upperBody, sets: sets, reps: "8-10",
                    notes: String(localized: "str.note.row", defaultValue: "Squeeze shoulder blades together. Posture maintenance for long efforts."),
                    requiresEquipment: true
                ),
            ]
        } else {
            return [
                StrengthExercise(
                    name: String(localized: "str.name.pushups", defaultValue: "Push-Ups"),
                    category: .upperBody, sets: sets, reps: "10-15",
                    notes: String(localized: "str.note.pushups", defaultValue: "Full range of motion. Modify on knees if needed.")
                ),
            ]
        }
    }

    // MARK: - Exercise Library: Activation

    private static func selectActivation(isGym: Bool) -> [StrengthExercise] {
        [
            StrengthExercise(
                name: String(localized: "str.name.gluteBridge", defaultValue: "Glute Bridge"),
                category: .lowerBody, sets: 2, reps: "12",
                notes: String(localized: "str.note.gluteBridgeAct", defaultValue: "Activate glutes before running or as standalone.")
            ),
            StrengthExercise(
                name: "Clamshell",
                category: .injuryPrevention, sets: 2, reps: String(localized: "str.reps.12side", defaultValue: "12 per side"),
                notes: String(localized: "str.note.clamshell", defaultValue: "Keep feet together. Feel the burn in outer hip.")
            ),
            StrengthExercise(
                name: "Bird Dog",
                category: .core, sets: 2, reps: String(localized: "str.reps.8side", defaultValue: "8 per side"),
                notes: String(localized: "str.note.birdDogAct", defaultValue: "Gentle core activation. Reach the opposite arm and leg, keep your back flat and still.")
            ),
            StrengthExercise(
                name: String(localized: "str.name.walkingLunge", defaultValue: "Walking Lunge"),
                category: .lowerBody, sets: 2, reps: String(localized: "str.reps.8leg", defaultValue: "8 per leg"),
                notes: String(localized: "str.note.walkingLungeAct", defaultValue: "Slow and controlled. Feel the stretch in hip flexors.")
            ),
        ]
    }

    // MARK: - Injury Prevention Exercises

    private static func selectInjuryPrevention(isGym: Bool, config: Config) -> [StrengthExercise] {
        var exercises: [StrengthExercise] = []
        let sets = 3

        // T13: discipline-specific injury-prevention emphasis.
        //
        // ROAD (Dicharry; Willy & Davis 2011; Pfitzinger): glute medius
        // dysfunction (Trendelenburg) and Achilles/calf overload are
        // the dominant injuries, ITBS, PFP, Achilles tendinopathy.
        // Side plank with hip abduction (Copenhagen-style) + slow-
        // eccentric calf raise are the keystone exercises.
        //
        // TRAIL (House/Johnston; Roche): eccentric quad damage from
        // descents + ankle sprains from technical terrain dominate.
        // Step-down + single-leg balance are the keystone.
        switch config.raceType {
        case .road:
            exercises.append(StrengthExercise(
                name: String(localized: "str.name.sidePlankAbd", defaultValue: "Side Plank with Hip Abduction"),
                category: .injuryPrevention, sets: sets, reps: String(localized: "str.reps.810side", defaultValue: "8-10 per side"),
                notes: String(localized: "str.note.sidePlankAbd", defaultValue: "Stack hips, lift the top leg slowly. Glute-med specific, directly counters the pelvic drop behind ITBS and PFP.")
            ))
            exercises.append(StrengthExercise(
                name: String(localized: "str.name.calfRaise", defaultValue: "Slow Eccentric Calf Raise"),
                category: .injuryPrevention, sets: sets, reps: "12-15",
                notes: String(localized: "str.note.calfRaise", defaultValue: "3-second lowering. Both straight and bent knee. The calf-Achilles complex absorbs ~3× bodyweight per stride, calf endurance predicts late-marathon pace fade.")
            ))
            if config.painFrequency == .often || config.hasRecentInjury {
                exercises.append(StrengthExercise(
                    name: "Russian Twist",
                    category: .injuryPrevention, sets: sets, reps: String(localized: "str.reps.10side", defaultValue: "10 per side"),
                    notes: String(localized: "str.note.russianTwistRoad", defaultValue: "Rotational core control. A steady trunk stops the energy-wasting twist that creeps in at high cadence.")
                ))
            }

        case .trail:
            exercises.append(StrengthExercise(
                name: "Clamshell with Band",
                category: .injuryPrevention, sets: sets, reps: String(localized: "str.reps.1215side", defaultValue: "12-15 per side"),
                notes: String(localized: "str.note.clamshellBand", defaultValue: "Glute medius activation. Prevents IT band issues and knee pain.")
            ))
            exercises.append(StrengthExercise(
                name: String(localized: "str.name.stepDown", defaultValue: "Step-Down (slow eccentric)"),
                category: .injuryPrevention, sets: sets, reps: String(localized: "str.reps.812leg", defaultValue: "8-12 per leg"),
                notes: String(localized: "str.note.stepDown", defaultValue: "30-50 cm box. 4-second lowering. Best single exercise for downhill quad tolerance, directly trains the eccentric loading that destroys late-race ultras.")
            ))
            if config.painFrequency == .often || config.hasRecentInjury {
                exercises.append(StrengthExercise(
                    name: String(localized: "str.name.hipHike", defaultValue: "Hip Hike on Step"),
                    category: .injuryPrevention, sets: sets, reps: String(localized: "str.reps.12side", defaultValue: "12 per side"),
                    notes: String(localized: "str.note.hipHike", defaultValue: "Stand on step edge. Lower hip then raise. Strengthens glute medius and hip stabilizers.")
                ))
                exercises.append(StrengthExercise(
                    name: String(localized: "str.name.ankleStar", defaultValue: "Ankle Stability - Star Reach"),
                    category: .injuryPrevention, sets: 2, reps: String(localized: "str.reps.3roundsLeg", defaultValue: "3 rounds per leg"),
                    notes: String(localized: "str.note.ankleStar", defaultValue: "Stand on one leg, reach other foot in 4 directions. Ankle proprioception for trails.")
                ))
            }
            // For ultra trail: extra ankle and quad eccentric work
            if config.raceEffectiveKm > 50 {
                exercises.append(StrengthExercise(
                    name: String(localized: "str.name.slBalanceClosed", defaultValue: "Single-Leg Balance (Eyes Closed)"),
                    category: .injuryPrevention, sets: 2, reps: String(localized: "str.reps.1520secLeg", defaultValue: "15-20 sec per leg"),
                    notes: String(localized: "str.note.slBalanceClosed", defaultValue: "Advanced proprioception. Essential for technical trail terrain.")
                ))
            }
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

    /// Calculates realistic working duration (excluding warmup, user manages their own).
    /// Per set: ~45-50sec work (8 reps x 5-6sec controlled tempo) + rest between sets.
    /// Plus ~45sec transition between exercises (set up, adjust weight, get in position).
    /// Rest varies by phase: base 60s, build 90-120s, peak 75s.
    /// Rounds to nearest 5 minutes for clean display.
    static func estimatedDuration(
        category: StrengthSessionCategory,
        exercises: [StrengthExercise],
        phase: TrainingPhase = .base
    ) -> Int {
        let restBetweenSets: Double
        switch category {
        case .full:
            switch phase {
            case .base: restBetweenSets = 90 // moderate load, still need recovery
            case .build: restBetweenSets = 120 // heavy loads, full neural recovery
            case .peak: restBetweenSets = 90
            default: restBetweenSets = 90
            }
        case .maintenance: restBetweenSets = 75
        case .activation: restBetweenSets = 45
        }

        let warmupMinutes = 10.0 // athlete will warm up + settle in, include in estimate

        var workingBlockSeconds: Double = 0
        for ex in exercises {
            let workPerSet: Double = 50 // 8-10 reps x ~5-6sec each with controlled tempo
            let sets = Double(ex.sets)
            let restPeriods = max(sets - 1, 0)
            let transitionTime: Double = 45 // set up equipment, adjust weight, get in position
            workingBlockSeconds += (sets * workPerSet) + (restPeriods * restBetweenSets) + transitionTime
        }

        let rawMinutes = warmupMinutes + (workingBlockSeconds / 60)
        let rounded = Int((rawMinutes / 5.0).rounded()) * 5
        return max(rounded, 20)
    }

    private static func workoutName(
        config: Config,
        category: StrengthSessionCategory,
        sessionIndex: Int
    ) -> String {
        let phaseName: String
        switch config.phase {
        case .base: phaseName = String(localized: "str.phase.foundation", defaultValue: "Foundation")
        case .build: phaseName = String(localized: "str.phase.strengthPower", defaultValue: "Strength-Power")
        case .peak: phaseName = String(localized: "str.phase.maintenance", defaultValue: "Maintenance")
        case .taper: phaseName = String(localized: "str.phase.activation", defaultValue: "Activation")
        case .recovery: phaseName = String(localized: "str.phase.recovery", defaultValue: "Recovery")
        case .race: phaseName = String(localized: "str.phase.preRace", defaultValue: "Pre-Race")
        }

        let locationSuffix = config.location == .gym ? String(localized: "str.loc.gym", defaultValue: "Gym") : String(localized: "str.loc.home", defaultValue: "Home")

        switch category {
        case .full:
            return String(localized: "str.wname.full", defaultValue: "\(phaseName) S&C (\(locationSuffix))")
        case .maintenance:
            return String(localized: "str.wname.quick", defaultValue: "\(phaseName) Quick S&C (\(locationSuffix))")
        case .activation:
            return String(localized: "str.wname.activation", defaultValue: "Activation & Mobility")
        }
    }
}
