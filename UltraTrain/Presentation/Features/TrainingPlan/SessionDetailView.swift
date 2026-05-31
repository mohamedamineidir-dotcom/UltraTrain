import SwiftUI

struct SessionDetailView: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession
    let planStartDate: Date
    let planEndDate: Date
    let swapCandidates: [SwapCandidate]
    let athlete: Athlete?
    let nutritionAdvisor: any SessionNutritionAdvisor
    let nutritionPreferences: NutritionPreferences
    var workouts: [IntervalWorkout] = []
    var onSkip: ((SkipReason) -> Void)?
    var onUnskip: (() -> Void)?
    var onReschedule: ((Date) -> Void)?
    var onSwap: ((SwapCandidate) -> Void)?
    var onValidate: (() -> Void)?
    var onValidateWithStats: ((Double?, TimeInterval?, Double?, PerceivedFeeling?, Int?) -> Void)?
    var onLinkRun: ((UUID) -> Void)?
    var recentRuns: [CompletedRun] = []
    var recentRunsProvider: ((Date) async -> [CompletedRun])?
    var stravaActivitiesProvider: ((Date) async -> [StravaActivity])?
    var onLinkStravaActivity: ((StravaActivity) -> Void)?
    /// IR-1: supplies the feedback-sheet context (target pace + rep count
    /// + existing feedback for re-edit) once validation dismisses. When
    /// provider returns nil, the follow-up sheet is skipped.
    var intervalFeedbackContextProvider: (() async -> IntervalFeedbackContext?)?
    var onSaveIntervalFeedback: ((IntervalPerformanceFeedback) -> Void)?
    var weekProgress: WeekProgress?
    /// Fires when the athlete validates a fitness-test session with
    /// variant-specific results. Variant is auto-detected from the
    /// session's `intervalFocus` field, no extra plumbing required.
    var onCompleteFitnessTest: ((FitnessTestVariant, TestResultInput, PerceivedFeeling?) -> Void)?

    @State private var showSkipReasonSheet = false
    @State private var showRescheduleSheet = false
    @State private var showSwapSheet = false
    @State private var showValidateSheet = false
    @State private var showRestSwapSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                headerSection

                if session.isSkipped {
                    skippedBanner
                }

                if session.type == .strengthConditioning {
                    // S&C-specific layout
                    scDurationCard
                    scExerciseList
                    if let advice = session.coachAdvice, !advice.isEmpty {
                        CoachAdviceCard(advice: advice, tint: session.intensity.color)
                    }
                } else {
                    statsSection

                    if let athlete, session.type != .rest {
                        paceTargetsSection(athlete: athlete)
                    }

                    // Resolve the linked workout once. When present,
                    // WorkoutBlocksSection carries the athlete-facing
                    // structure + per-phase visual breakdown, the
                    // standalone Description / Session-Structure cards
                    // become redundant and are dropped to keep the
                    // page tight (user feedback: too many cards).
                    let resolvedWorkout: IntervalWorkout? = {
                        guard let id = session.intervalWorkoutId else { return nil }
                        return workouts.first(where: { $0.id == id && !$0.phases.isEmpty })
                    }()

                    if resolvedWorkout == nil {
                        // No structured workout → keep the description
                        // text card as the only place the athlete sees
                        // what they're meant to do.
                        descriptionSection
                    }

                    if let workout = resolvedWorkout {
                        WorkoutBlocksSection(
                            workout: workout,
                            athlete: athlete,
                            purposeLine: RoadIntervalLibrary.purposeLine(for: session.intervalFocus)
                        )
                    }

                    if let advice = session.coachAdvice, !advice.isEmpty {
                        CoachAdviceCard(advice: advice, tint: session.intensity.color)
                    }

                    if let athlete,
                       let advice = nutritionAdvisor.advise(
                        for: session,
                        athleteWeightKg: athlete.weightKg,
                        experienceLevel: athlete.experienceLevel,
                        preferences: nutritionPreferences
                       ) {
                        SessionNutritionSection(advice: advice)
                    } else if let notes = session.nutritionNotes {
                        nutritionSection(notes)
                    }

                    // #20: race-week carb-loading + hydration protocol.
                    // Only surfaces on the race session itself, where
                    // the athlete is most likely to look for fuelling
                    // guidance. The card uses the race's planned
                    // duration as the estimated finish time.
                    if session.type == .race,
                       let athlete, athlete.weightKg > 0,
                       session.plannedDuration > 0 {
                        RaceWeekFuellingCard(
                            athleteWeightKg: athlete.weightKg,
                            estimatedRaceDurationSeconds: session.plannedDuration,
                            preRaceMealTiming: nutritionPreferences.preRaceMealTiming
                        )
                    }

                    // Palate-timing strategy card. Only for ultra
                    // distances (≥ 60 km) where flavour fatigue becomes
                    // a real factor, and only when the athlete told us
                    // in onboarding when their palate typically shifts.
                    if session.type == .race,
                       session.plannedDistanceKm >= 60,
                       let palateTiming = nutritionPreferences.ultraPalateTiming {
                        UltraAidStationCard(
                            palateTiming: palateTiming,
                            raceDistanceKm: session.plannedDistanceKm
                        )
                    }
                }

                actionsSection
            }
            .padding()
        }
        .navigationTitle(session.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSkipReasonSheet) {
            SkipReasonSheet(sessionType: session.type) { reason in
                onSkip?(reason)
            }
        }
        .sheet(isPresented: $showRescheduleSheet) {
            RescheduleDateSheet(
                currentDate: session.date,
                planStartDate: planStartDate,
                planEndDate: planEndDate,
                onReschedule: { newDate in onReschedule?(newDate) }
            )
        }
        .sheet(isPresented: $showSwapSheet) {
            SwapSessionSheet(
                currentSession: session,
                availableSessions: swapCandidates,
                onSwap: { candidate in onSwap?(candidate) }
            )
        }
        .sheet(isPresented: $showRestSwapSheet) {
            RestDaySwapSheet(
                currentSession: session,
                weekCandidates: sameWeekCandidates,
                onSelect: { candidate in onSwap?(candidate) }
            )
        }
        .sheet(isPresented: $showValidateSheet) {
            SessionValidationView(
                session: session,
                recentRuns: recentRuns,
                onComplete: { dist, dur, elev, feeling, exertion in
                    if dist != nil || dur != nil || elev != nil || feeling != nil || exertion != nil {
                        onValidateWithStats?(dist, dur, elev, feeling, exertion)
                    } else {
                        onValidate?()
                    }
                },
                onLinkRun: { runId in onLinkRun?(runId) },
                recentRunsProvider: recentRunsProvider,
                stravaActivitiesProvider: stravaActivitiesProvider,
                onLinkStravaActivity: onLinkStravaActivity,
                intervalFeedbackContextProvider: intervalFeedbackContextProvider,
                onSaveIntervalFeedback: onSaveIntervalFeedback,
                weekProgress: weekProgress,
                onCompleteFitnessTest: onCompleteFitnessTest
            )
        }
    }

    // MARK: - Same-week candidates

    /// Swap candidates filtered to the same calendar week as the current
    /// session. Used by RestDaySwapSheet so the athlete only sees days
    /// from the rest day's own week, cross-week noise would defeat the
    /// "pick when to rest this week" mental model.
    private var sameWeekCandidates: [SwapCandidate] {
        let calendar = Calendar.current
        return swapCandidates.filter { candidate in
            calendar.isDate(candidate.session.date, equalTo: session.date, toGranularity: .weekOfYear)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        let tint = session.isSkipped ? Theme.Colors.tertiaryLabel : session.intensity.color
        return HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Glowing icon disc, replaces the bare large-title icon.
            // Anchors the eye and ties to the session's intensity color.
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(tint.opacity(0.4), lineWidth: 1)
                    .frame(width: 56, height: 56)
                Image(systemName: session.type.icon)
                    .font(.title2)
                    .foregroundStyle(tint)
            }
            .shadow(color: tint.opacity(0.3), radius: 8, y: 2)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.title2.bold())
                if let focus = session.intervalFocus {
                    Text(focus.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(tint)
                }
                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                Text(session.intensity.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                if let zone = session.targetHeartRateZone {
                    SessionZoneTargetBadge(zone: zone)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: tint)
        .accessibilityIdentifier("trainingPlan.sessionDetail.header")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        var label = "\(session.type.displayName), \(session.intensity.displayName) intensity"
        label += ". \(session.date.formatted(.dateTime.weekday(.wide).month().day()))"
        if let zone = session.targetHeartRateZone {
            label += ". Target heart rate zone \(zone)"
        }
        if session.isSkipped {
            label += ". Skipped"
        } else if session.isCompleted {
            label += ". Completed"
        }
        return label
    }

    // MARK: - Skipped Banner

    private var skippedBanner: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "forward.fill")
                .foregroundStyle(Theme.Colors.warning)
                .accessibilityHidden(true)
            Text("Skipped")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.warning)
            Spacer()
            if onUnskip != nil {
                Button("Undo") { onUnskip?() }
                    .font(.subheadline.bold())
                    .accessibilityIdentifier("trainingPlan.session.unskip")
                    .accessibilityHint("Double-tap to restore this session")
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.warning.opacity(0.12))
        )
    }

    // MARK: - Stats

    private var isTimeBased: Bool {
        session.type == .longRun || session.type == .backToBack || session.type == .race
    }

    private var statsSection: some View {
        // Stats trio shares the intensity tint with the header, they
        // sit on the same line as a paired "what is this session"
        // block, so different colours per stat read as noise.
        let tint = session.intensity.color
        return HStack(spacing: Theme.Spacing.sm) {
            if isTimeBased {
                if session.plannedDuration > 0 {
                    StatCard(
                        title: "Duration",
                        value: session.plannedDuration.formattedDuration,
                        unit: "",
                        tint: tint
                    )
                }
                if session.plannedElevationGainM > 0 {
                    StatCard(
                        title: "Elevation",
                        value: String(format: "%.0f", UnitFormatter.elevationValue(session.plannedElevationGainM, unit: units)),
                        unit: UnitFormatter.elevationLabel(units),
                        tint: tint
                    )
                }
                if session.plannedDistanceKm > 0 {
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.1f", UnitFormatter.distanceValue(session.plannedDistanceKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units),
                        tint: tint
                    )
                }
            } else {
                if session.plannedDistanceKm > 0 {
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.1f", UnitFormatter.distanceValue(session.plannedDistanceKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units),
                        tint: tint
                    )
                }
                if session.plannedElevationGainM > 0 {
                    StatCard(
                        title: "Elevation",
                        value: String(format: "%.0f", UnitFormatter.elevationValue(session.plannedElevationGainM, unit: units)),
                        unit: UnitFormatter.elevationLabel(units),
                        tint: tint
                    )
                }
                if session.plannedDuration > 0 {
                    StatCard(
                        title: "Duration",
                        value: session.plannedDuration.formattedDuration,
                        unit: "",
                        tint: tint
                    )
                }
            }
        }
    }

    // MARK: - S&C Duration Card

    private var scDurationCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.zone2)
                Text(session.plannedDuration.formattedDuration)
                    .font(.title2.bold().monospacedDigit())
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Theme.Colors.tertiaryLabel.opacity(0.2))
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.zone3)
                Text("\(scExerciseCount)")
                    .font(.title2.bold().monospacedDigit())
                Text("Exercises")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
        }
        .futuristicGlassStyle(phaseTint: Theme.Colors.zone3)
    }

    private var scExerciseCount: Int {
        // Count bullet points in description as proxy for exercise count
        session.description.components(separatedBy: "\u{2022}").count - 1
    }

    // MARK: - S&C Exercise List

    private var scExerciseList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(parseSCExercises().enumerated()), id: \.offset) { index, exercise in
                if index > 0 {
                    Divider()
                        .padding(.leading, 48)
                }
                scExerciseRow(exercise, number: index + 1)
            }
        }
        .cardStyle()
    }

    private func scExerciseRow(_ exercise: SCParsedExercise, number: Int) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Exercise number circle
            Text("\(number)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [Theme.Colors.zone2, Theme.Colors.zone3],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                Text(exercise.setsReps)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.Colors.warmCoral)
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.sm)
    }

    /// Parses the S&C description text into structured exercise data.
    private func parseSCExercises() -> [SCParsedExercise] {
        var exercises: [SCParsedExercise] = []
        let lines = session.description.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("\u{2022}") {
                // Exercise line: "• Exercise Name, 3×10-12"
                let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                let parts = content.components(separatedBy: " \u{2014} ")
                if parts.count >= 2 {
                    exercises.append(SCParsedExercise(
                        name: parts[0].trimmingCharacters(in: .whitespaces),
                        setsReps: parts[1].trimmingCharacters(in: .whitespaces),
                        notes: ""
                    ))
                } else {
                    exercises.append(SCParsedExercise(name: content, setsReps: "", notes: ""))
                }
            } else if !exercises.isEmpty && !trimmed.isEmpty
                        && !trimmed.hasPrefix("\u{25B8}") && !trimmed.hasPrefix("Duration")
                        && !trimmed.contains("warm-up") && !trimmed.contains("cool-down")
                        && !trimmed.hasPrefix("Foundation") && !trimmed.hasPrefix("Strength")
                        && !trimmed.hasPrefix("Maintenance") && !trimmed.hasPrefix("Activation")
                        && !trimmed.hasPrefix("Climbing") {
                // Notes line under the last exercise
                exercises[exercises.count - 1].notes = trimmed
            }
        }

        return exercises
    }

    // MARK: - Description

    private var descriptionSection: some View {
        // Paired with the Pace & HR card above under the info tint
        // both are reference / detail cards, so sharing a colour
        // groups them visually as the "session reference" block.
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Description", systemImage: "text.alignleft")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.info)
            Text(session.description)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.info)
    }

    private func nutritionSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Nutrition", systemImage: "fork.knife")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.warning)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.warning)
    }

    // MARK: - Pace & HR Targets

    @ViewBuilder
    private func paceTargetsSection(athlete: Athlete) -> some View {
        if let thresholdPace = athlete.thresholdPace60MinPerKm, thresholdPace > 0 {
            let hrRange = PaceCalculator.heartRateRange(
                for: session.intensity,
                restingHR: athlete.restingHeartRate,
                maxHR: athlete.maxHeartRate
            )
            // Pace + HR card uses the info (cyan) tint so it reads as
            // "metrics / data" and contrasts with the intensity-tinted
            // header sitting two cards above.
            let metricsTint = Theme.Colors.info

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if showsEffortInsteadOfPace {
                    Label("Effort & Heart Rate Targets", systemImage: "speedometer")
                        .font(.headline)
                        .foregroundStyle(metricsTint)
                } else {
                    Label("Pace & Heart Rate Targets", systemImage: "speedometer")
                        .font(.headline)
                        .foregroundStyle(metricsTint)
                }

                HStack(spacing: Theme.Spacing.lg) {
                    if showsEffortInsteadOfPace {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Effort")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                            Text(effortDescription(for: session.intensity))
                                .font(.subheadline.bold())
                                .foregroundStyle(metricsTint)
                        }
                    } else {
                        let range = PaceCalculator.paceRange(for: session.intensity, thresholdPacePerKm: thresholdPace)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Pace")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                            Text("\(PaceCalculator.formatPace(range.min)) - \(PaceCalculator.formatPace(range.max)) /km")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(metricsTint)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heart Rate")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text("\(hrRange.min) - \(hrRange.max) bpm")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(metricsTint)
                    }
                }

                if let zone = session.targetHeartRateZone {
                    Text("Zone \(zone) (\(session.intensity.displayName))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .futuristicGlassStyle(phaseTint: metricsTint)
        }
    }

    private var showsEffortInsteadOfPace: Bool {
        session.type == .verticalGain || session.type == .longRun || session.type == .backToBack || session.type == .race
    }

    private func effortDescription(for intensity: Intensity) -> String {
        switch intensity {
        case .easy:      "Easy pace"
        case .moderate:  "Threshold effort"
        case .hard:      "VO2max effort"
        case .maxEffort: "All-out effort"
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !session.isCompleted && !session.isSkipped && session.type != .rest {
                Button {
                    showValidateSheet = true
                } label: {
                    Label("Validate Session", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.sessionPrimary(tint: Theme.Colors.success))
                .accessibilityIdentifier("trainingPlan.session.validate")
                .accessibilityHint("Double-tap to validate this session as completed")
            }

            if session.type == .rest && !session.isCompleted && !session.isSkipped {
                Button {
                    showRestSwapSheet = true
                } label: {
                    Label("Move Rest Day", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.sessionPrimary(tint: Theme.Colors.warmCoral))
                .accessibilityIdentifier("trainingPlan.session.moveRest")
                .accessibilityHint("Double-tap to move your rest day to another day this week")
            }

            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSkipReasonSheet = true
                } label: {
                    Label("Skip Session", systemImage: "forward.fill")
                }
                .buttonStyle(.sessionSecondary(tint: Theme.Colors.amberAccent))
                .accessibilityIdentifier("trainingPlan.session.skip")
                .accessibilityHint("Double-tap to skip this session and explain why")
            }

            if !session.isCompleted {
                Button {
                    showRescheduleSheet = true
                } label: {
                    Label("Reschedule", systemImage: "calendar.badge.clock")
                }
                .buttonStyle(.sessionSecondary(tint: Theme.Colors.info))
                .accessibilityIdentifier("trainingPlan.session.reschedule")
                .accessibilityHint("Double-tap to move this session to a different date")
            }

            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSwapSheet = true
                } label: {
                    Label("Swap with Another Session", systemImage: "arrow.triangle.swap")
                }
                .buttonStyle(.sessionSecondary(tint: Theme.Colors.info))
                .accessibilityIdentifier("trainingPlan.session.swap")
                .accessibilityHint("Double-tap to swap this session with another one")
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - S&C Parsed Exercise

private struct SCParsedExercise {
    let name: String
    let setsReps: String
    var notes: String
}
