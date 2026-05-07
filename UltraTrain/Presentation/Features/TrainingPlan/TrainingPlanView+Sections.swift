import SwiftUI

// MARK: - Plan Content, Headers, Banners & Empty State

extension TrainingPlanView {

    func planContent(_ plan: TrainingPlan) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                if viewModel.isPlanStale {
                    stalePlanBanner
                }

                if !viewModel.visibleRecommendations.isEmpty {
                    PlanAdjustmentBanner(
                        recommendations: viewModel.visibleRecommendations,
                        isApplying: viewModel.isApplyingAdjustment,
                        onApply: { rec in
                            Task { await viewModel.applyRecommendation(rec) }
                        },
                        onDismiss: { rec in
                            viewModel.dismissRecommendation(rec)
                        }
                    )
                }

                // #22: ACWR / monotony projection for the next 7 days.
                // Evidence-backed injury signal surfaced BEFORE the
                // athlete executes the week rather than after.
                if viewModel.shouldShowInjuryRiskBanner,
                   let projection = viewModel.injuryRiskProjection {
                    InjuryRiskBanner(
                        projection: projection,
                        onDismiss: {
                            viewModel.injuryRiskBannerDismissed = true
                        }
                    )
                }

                // #26: sustained missed-session pattern. Closes the
                // loop between plan assumptions and actual execution.
                if viewModel.shouldShowMissedSessionBanner,
                   let pattern = viewModel.missedSessionPattern {
                    MissedSessionBanner(
                        pattern: pattern,
                        onRegenerate: {
                            Task { await viewModel.generatePlan() }
                        },
                        onDismiss: {
                            viewModel.missedSessionBannerDismissed = true
                        },
                        isRegenerating: viewModel.isGenerating
                    )
                }

                planHeader(plan)

                let isRoadPlan = viewModel.targetRace?.raceType == .road

                PlanVolumeChartsSection(plan: plan, isRoad: isRoadPlan)

                ForEach(Array(viewModel.visibleWeeks.enumerated()), id: \.element.id) { visibleIndex, week in
                    let weekIndex = plan.weeks.firstIndex(where: { $0.id == week.id }) ?? 0

                    // Phase header at phase transitions
                    if visibleIndex == 0 || week.phase != viewModel.visibleWeeks[visibleIndex - 1].phase {
                        let phaseWeeks = plan.weeks.filter { $0.phase == week.phase }
                        let completedWeeks = phaseWeeks.filter { w in
                            w.sessions.filter { $0.type != .rest && !$0.isSkipped }.allSatisfy(\.isCompleted)
                        }.count
                        let firstNum = phaseWeeks.first?.weekNumber ?? 1
                        let lastNum = phaseWeeks.last?.weekNumber ?? 1
                        PhaseHeaderCard(
                            phase: week.phase,
                            weekRange: "Weeks \(firstNum)-\(lastNum)",
                            completedWeeks: completedWeeks,
                            totalWeeks: phaseWeeks.count,
                            description: PhaseHeaderCard.description(for: week.phase, focus: week.phaseFocus, isRoad: isRoadPlan),
                            phaseFocus: week.phaseFocus,
                            isRoad: isRoadPlan
                        )
                    }

                    WeekCardView(
                        week: week,
                        weekIndex: weekIndex,
                        isCurrentWeek: week.containsToday,
                        planStartDate: plan.weeks.first?.startDate ?? .now,
                        planEndDate: plan.weeks.last?.endDate ?? .now,
                        allWeeks: plan.weeks,
                        athlete: viewModel.athlete,
                        isRoad: isRoadPlan,
                        nutritionAdvisor: viewModel.nutritionAdvisor,
                        nutritionPreferences: viewModel.nutritionPreferences,
                        onToggleSession: { sessionIndex in
                            Task {
                                await viewModel.toggleSessionCompletion(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex
                                )
                            }
                        },
                        onSkipSession: { sessionIndex, reason in
                            Task {
                                await viewModel.skipSession(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex,
                                    reason: reason
                                )
                            }
                        },
                        onUnskipSession: { sessionIndex in
                            Task {
                                await viewModel.unskipSession(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex
                                )
                            }
                        },
                        onRescheduleSession: { sessionIndex, newDate in
                            Task {
                                await viewModel.rescheduleSession(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex,
                                    to: newDate
                                )
                            }
                        },
                        onSwapSession: { sessionIndex, candidate in
                            Task {
                                await viewModel.swapSessions(
                                    weekIndexA: weekIndex,
                                    sessionIndexA: sessionIndex,
                                    weekIndexB: candidate.weekIndex,
                                    sessionIndexB: candidate.sessionIndex
                                )
                            }
                        },
                        workouts: plan.workouts,
                        onReorderSession: { sourceWeekIndex, sourceSessionIndex, target in
                            Task {
                                await viewModel.swapSessions(
                                    weekIndexA: sourceWeekIndex,
                                    sessionIndexA: sourceSessionIndex,
                                    weekIndexB: target.weekIndex,
                                    sessionIndexB: target.sessionIndex
                                )
                            }
                        },
                        onValidateSession: { sessionIndex in
                            Task {
                                await viewModel.toggleSessionCompletion(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex
                                )
                            }
                        },
                        onValidateSessionWithStats: { sessionIndex, dist, dur, elev, feeling, exertion in
                            Task {
                                await viewModel.completeSessionManually(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex,
                                    distanceKm: dist,
                                    durationSeconds: dur,
                                    elevationGainM: elev,
                                    feeling: feeling,
                                    exertion: exertion
                                )
                            }
                        },
                        onLinkSessionToRun: { sessionIndex, runId in
                            Task {
                                await viewModel.linkSessionToRun(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex,
                                    runId: runId
                                )
                            }
                        },
                        recentRunsProvider: { date in
                            await viewModel.recentUnlinkedRuns(near: date)
                        },
                        stravaActivitiesProvider: { date in
                            await viewModel.recentStravaActivities(near: date)
                        },
                        onLinkStravaActivity: { sessionIndex, activity in
                            Task {
                                await viewModel.importAndLinkStravaActivity(
                                    weekIndex: weekIndex,
                                    sessionIndex: sessionIndex,
                                    activity: activity
                                )
                            }
                        },
                        intervalFeedbackContextProvider: { sessionIndex in
                            await buildIntervalFeedbackContext(
                                weekIndex: weekIndex,
                                sessionIndex: sessionIndex
                            )
                        },
                        onSaveIntervalFeedback: { feedback in
                            Task { await viewModel.saveIntervalFeedback(feedback) }
                        }
                    )
                }

                if viewModel.hasLockedWeeks {
                    lockedWeeksBanner
                }
            }
            .padding()
        }
    }

    @MainActor
    private func buildIntervalFeedbackContext(
        weekIndex: Int,
        sessionIndex: Int
    ) async -> IntervalFeedbackContext? {
        guard viewModel.sessionQualifiesForIntervalFeedback(
            weekIndex: weekIndex, sessionIndex: sessionIndex
        ) else { return nil }
        guard let pace = viewModel.targetPacePerKm(
            weekIndex: weekIndex, sessionIndex: sessionIndex
        ), pace > 0 else { return nil }
        guard let plan = viewModel.plan,
              weekIndex < plan.weeks.count,
              sessionIndex < plan.weeks[weekIndex].sessions.count else { return nil }
        let session = plan.weeks[weekIndex].sessions[sessionIndex]
        let reps = viewModel.prescribedRepCount(
            weekIndex: weekIndex, sessionIndex: sessionIndex
        )
        guard reps > 0 else { return nil }
        let existing = await viewModel.loadIntervalFeedback(sessionId: session.id)
        let label = "\(session.type.displayName) · \(session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))"
        return IntervalFeedbackContext(
            id: UUID(),
            sessionId: session.id,
            sessionType: session.type,
            sessionLabel: label,
            targetPacePerKm: pace,
            prescribedRepCount: reps,
            existingFeedback: existing
        )
    }

    var lockedWeeksBanner: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.goldAccent.opacity(0.2), Theme.Colors.goldAccent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(Theme.Colors.goldAccent)
                    .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 3)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(viewModel.lockedWeekCount) More Weeks")
                    .font(.subheadline.bold())
                Text(viewModel.lockedWeeksBannerSubtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.goldAccent.opacity(0.6))
        }
        .futuristicGlassStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.goldAccent.opacity(0.15), lineWidth: 1)
        )
        .accessibilityLabel("\(viewModel.lockedWeekCount) locked weeks. Upgrade to view.")
    }

    func planHeader(_ plan: TrainingPlan) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("\(plan.totalWeeks)-Week Plan")
                        .font(.title3.bold())

                    if let currentWeek = viewModel.currentWeek {
                        HStack(spacing: Theme.Spacing.xs) {
                            Circle()
                                .fill(currentWeek.phase.color)
                                .frame(width: 8, height: 8)
                                .shadow(color: currentWeek.phase.color.opacity(0.5), radius: 3)
                            Text("Week \(currentWeek.weekNumber)")
                                .font(.subheadline.weight(.semibold))
                            Text("·")
                                .foregroundStyle(Theme.Colors.tertiaryLabel)
                            Text(currentWeek.phase.displayName)
                                .font(.subheadline)
                                .foregroundStyle(currentWeek.phase.color)
                        }
                    }
                }
                Spacer()
                let progress = viewModel.weeklyProgress
                if progress.total > 0 {
                    weekProgressRing(completed: progress.completed, total: progress.total)
                }
            }

            // Overall progress bar
            overallProgressBar(plan: plan)
        }
        .futuristicGlassStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(planHeaderAccessibilityLabel(plan))
    }

    private func weekProgressRing(completed: Int, total: Int) -> some View {
        let fraction = total > 0 ? Double(completed) / Double(total) : 0
        return ZStack {
            Circle()
                .stroke(Theme.Colors.secondaryLabel.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    LinearGradient(
                        colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.Colors.success.opacity(0.3), radius: 4)
            VStack(spacing: 0) {
                Text("\(completed)/\(total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                Text("this week")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(width: 56, height: 56)
    }

    private func overallProgressBar(plan: TrainingPlan) -> some View {
        let totalSessions = plan.weeks.flatMap(\.sessions).filter { $0.type != .rest && !$0.isSkipped }
        let done = totalSessions.filter(\.isCompleted).count
        let total = totalSessions.count
        let fraction = total > 0 ? Double(done) / Double(total) : 0
        return VStack(spacing: Theme.Spacing.xs) {
            HStack {
                Text("Overall Progress")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Spacer()
                Text("\(done)/\(total) sessions")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.secondaryLabel.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.success.opacity(0.7), Theme.Colors.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Theme.Colors.success.opacity(0.3), radius: 3)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
    }

    func planHeaderAccessibilityLabel(_ plan: TrainingPlan) -> String {
        var label = "\(plan.totalWeeks) week training plan"
        if let currentWeek = viewModel.currentWeek {
            label += ". Currently in week \(currentWeek.weekNumber), \(currentWeek.phase.displayName) phase"
        }
        let progress = viewModel.weeklyProgress
        if progress.total > 0 {
            label += ". \(progress.completed) of \(progress.total) sessions completed this week"
        }
        return label
    }

    var stalePlanBanner: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.warning.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundStyle(Theme.Colors.warning)
                    .shadow(color: Theme.Colors.warning.opacity(0.4), radius: 3)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Plan May Be Outdated")
                    .font(.subheadline.bold())
                Text(staleBannerDescription)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Button {
                viewModel.showRegenerateConfirmation = true
            } label: {
                Text("Update")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.warning)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("trainingPlan.staleBanner.update")
            .accessibilityHint("Double-tap to regenerate your training plan")
        }
        .futuristicGlassStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.warning.opacity(0.15), lineWidth: 1)
        )
    }

    var staleBannerDescription: String {
        let summary = viewModel.raceChangeSummary
        var parts: [String] = []
        if !summary.added.isEmpty {
            let names = summary.added.map(\.name).joined(separator: ", ")
            parts.append("Added: \(names)")
        }
        if !summary.removed.isEmpty {
            let count = summary.removed.count
            parts.append("Removed: \(count) races")
        }
        if parts.isEmpty {
            return "Your races have changed since this plan was generated."
        }
        return parts.joined(separator: ". ") + "."
    }

    var regenerateDialogMessage: String {
        let summary = viewModel.raceChangeSummary
        var lines: [String] = ["Your race schedule has changed."]
        if !summary.added.isEmpty {
            let names = summary.added.map(\.name).joined(separator: ", ")
            lines.append("Added: \(names)")
        }
        if !summary.removed.isEmpty {
            let count = summary.removed.count
            lines.append("Removed: \(count) races")
        }
        lines.append("The plan will be regenerated with taper and recovery adjustments. Completed sessions will be preserved where possible.")
        return lines.joined(separator: "\n")
    }

    var emptyState: some View {
        FeatureEmptyState(
            icon: "calendar.badge.plus",
            title: "No Training Plan",
            message: "Generate a personalized plan based on your profile and race goals.",
            tint: Theme.Colors.accentColor,
            primaryAction: FeatureEmptyState.Action(
                title: "Generate Plan",
                systemImage: "sparkles"
            ) {
                Task { await viewModel.generatePlan() }
            },
            isPrimaryLoading: viewModel.isGenerating
        )
        .accessibilityIdentifier("trainingPlan.emptyState")
    }
}
