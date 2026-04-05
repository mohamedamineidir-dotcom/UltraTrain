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
    var onSkip: (() -> Void)?
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

    @State private var showSkipConfirmation = false
    @State private var showRescheduleSheet = false
    @State private var showSwapSheet = false
    @State private var showValidateSheet = false

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
                    if let advice = session.coachAdvice {
                        coachAdviceSection(advice)
                    }
                } else {
                    statsSection

                    if let athlete, session.type != .rest {
                        paceTargetsSection(athlete: athlete)
                    }

                    descriptionSection

                    if let workoutId = session.intervalWorkoutId,
                       let workout = workouts.first(where: { $0.id == workoutId }),
                       !workout.phases.isEmpty {
                        sessionStructureSummary(workout: workout)
                        WorkoutBlocksSection(workout: workout, athlete: athlete)
                    }

                    if let advice = session.coachAdvice {
                        coachAdviceSection(advice)
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
                }

                actionsSection
            }
            .padding()
        }
        .navigationTitle(session.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Skip Session?", isPresented: $showSkipConfirmation) {
            Button("Skip", role: .destructive) { onSkip?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This session will be marked as skipped and excluded from your weekly progress.")
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
                onLinkStravaActivity: onLinkStravaActivity
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient intensity bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [session.intensity.color.opacity(0.6), session.intensity.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
                .padding(.bottom, Theme.Spacing.sm)

            HStack {
                Image(systemName: session.type.icon)
                    .font(.largeTitle)
                    .foregroundStyle(session.isSkipped ? Theme.Colors.secondaryLabel : session.intensity.color)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(session.type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                VStack(spacing: Theme.Spacing.xs) {
                    Text(session.intensity.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(session.isSkipped ? Color.gray : session.intensity.color)
                        .clipShape(Capsule())

                    if let zone = session.targetHeartRateZone {
                        SessionZoneTargetBadge(zone: zone)
                    }
                }
            }
        }
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
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("Skipped")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
            Spacer()
            if onUnskip != nil {
                Button("Undo") { onUnskip?() }
                    .font(.subheadline.bold())
                    .accessibilityHint("Double-tap to restore this session")
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.orange.opacity(0.12))
        )
    }

    // MARK: - Stats

    private var isTimeBased: Bool {
        session.type == .longRun || session.type == .backToBack
    }

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            if isTimeBased {
                if session.plannedDuration > 0 {
                    StatCard(
                        title: "Duration",
                        value: session.plannedDuration.formattedDuration,
                        unit: ""
                    )
                }
                if session.plannedElevationGainM > 0 {
                    StatCard(
                        title: "Elevation",
                        value: String(format: "%.0f", UnitFormatter.elevationValue(session.plannedElevationGainM, unit: units)),
                        unit: UnitFormatter.elevationLabel(units)
                    )
                }
                if session.plannedDistanceKm > 0 {
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.1f", UnitFormatter.distanceValue(session.plannedDistanceKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units)
                    )
                }
            } else {
                if session.plannedDistanceKm > 0 {
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.1f", UnitFormatter.distanceValue(session.plannedDistanceKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units)
                    )
                }
                if session.plannedElevationGainM > 0 {
                    StatCard(
                        title: "Elevation",
                        value: String(format: "%.0f", UnitFormatter.elevationValue(session.plannedElevationGainM, unit: units)),
                        unit: UnitFormatter.elevationLabel(units)
                    )
                }
                if session.plannedDuration > 0 {
                    StatCard(
                        title: "Duration",
                        value: session.plannedDuration.formattedDuration,
                        unit: ""
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
        .padding(Theme.Spacing.md)
        .cardStyle()
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
                // Exercise line: "• Exercise Name — 3×10-12"
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Description")
                .font(.headline)
            Text(session.description)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func coachAdviceSection(_ advice: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Coach", systemImage: "quote.bubble.fill")
                .font(.headline)
                .foregroundStyle(Theme.Colors.warmCoral)
            Text(advice)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func nutritionSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Nutrition", systemImage: "fork.knife")
                .font(.headline)
            Text(notes)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
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

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if showsEffortInsteadOfPace {
                    Label("Effort & Heart Rate Targets", systemImage: "speedometer")
                        .font(.headline)
                } else {
                    Label("Pace & Heart Rate Targets", systemImage: "speedometer")
                        .font(.headline)
                }

                HStack(spacing: Theme.Spacing.lg) {
                    if showsEffortInsteadOfPace {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Effort")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                            Text(effortDescription(for: session.intensity))
                                .font(.subheadline.bold())
                                .foregroundStyle(session.intensity.color)
                        }
                    } else {
                        let range = PaceCalculator.paceRange(for: session.intensity, thresholdPacePerKm: thresholdPace)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Pace")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                            Text("\(PaceCalculator.formatPace(range.min)) - \(PaceCalculator.formatPace(range.max)) /km")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(session.intensity.color)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heart Rate")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                        Text("\(hrRange.min) - \(hrRange.max) bpm")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(session.intensity.color)
                    }
                }

                if let zone = session.targetHeartRateZone {
                    Text("Zone \(zone) (\(session.intensity.displayName))")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private var showsEffortInsteadOfPace: Bool {
        session.type == .verticalGain || session.type == .longRun || session.type == .backToBack
    }

    private func effortDescription(for intensity: Intensity) -> String {
        switch intensity {
        case .easy:      "Easy pace"
        case .moderate:  "Threshold effort"
        case .hard:      "VO2max effort"
        case .maxEffort: "All-out effort"
        }
    }

    // MARK: - Session Structure Summary

    private func sessionStructureSummary(workout: IntervalWorkout) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Session Structure", systemImage: "list.bullet.rectangle")
                .font(.headline)
            Text(buildStructureSummary(workout: workout))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func buildStructureSummary(workout: IntervalWorkout) -> String {
        var parts: [String] = []
        for phase in workout.phases {
            let perRepSeconds: Int
            if case .duration(let sec) = phase.trigger {
                perRepSeconds = Int(sec)
            } else {
                perRepSeconds = 0
            }
            switch phase.phaseType {
            case .warmUp:
                let mins = Int(phase.totalDuration) / 60
                parts.append("Warmup \(mins)min")
            case .coolDown:
                let mins = Int(phase.totalDuration) / 60
                parts.append("Cooldown \(mins)min")
            case .work:
                let mins = perRepSeconds / 60
                let secs = perRepSeconds % 60
                let timeStr = secs > 0 ? "\(mins)m\(secs)s" : "\(mins)min"
                if phase.repeatCount > 1 {
                    parts.append("\(phase.repeatCount)×\(timeStr) @ \(phase.targetIntensity.displayName)")
                } else {
                    parts.append("\(timeStr) @ \(phase.targetIntensity.displayName)")
                }
            case .recovery:
                let mins = perRepSeconds / 60
                let secs = perRepSeconds % 60
                if mins > 0 || secs > 0 {
                    let timeStr = secs > 0 ? "\(mins)m\(secs)s" : "\(mins)min"
                    parts.append("\(timeStr) jog")
                }
            }
        }
        return parts.joined(separator: " → ")
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !session.isCompleted && !session.isSkipped && session.type != .rest {
                Button {
                    showValidateSheet = true
                } label: {
                    Label("Validate Session", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.success)
                .accessibilityHint("Double-tap to validate this session as completed")
            }

            Divider()

            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSkipConfirmation = true
                } label: {
                    Label("Skip Session", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .accessibilityHint("Double-tap to skip this session")
            }

            if !session.isCompleted {
                Button {
                    showRescheduleSheet = true
                } label: {
                    Label("Reschedule", systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Double-tap to move this session to a different date")
            }

            if !session.isCompleted && !session.isSkipped {
                Button {
                    showSwapSheet = true
                } label: {
                    Label("Swap with Another Session", systemImage: "arrow.triangle.swap")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
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
