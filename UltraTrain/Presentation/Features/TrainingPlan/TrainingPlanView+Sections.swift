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
                    .premiumLocked(
                        title: String(localized: "premium.lock.volumeChart.title",
                                      defaultValue: "Training trends"),
                        message: String(localized: "premium.lock.volumeChart.message",
                                        defaultValue: "See how your volume builds across the whole block.")
                    )

                // Phase-paginated weeks. The flat vertical list of all
                // weeks meant a 26-week plan required ~5 screenfuls of
                // scroll to reach the end. Now the page shows ONE phase
                // at a time (Base / Build / Peak / Taper / Race), with
                // arrow buttons + dots indicator + horizontal swipe to
                // move between phases. Top charts and bottom banners are
                // unchanged, only the weeks list is paginated.
                let groups = phaseGroups(plan: plan)
                if !groups.isEmpty {
                    let safeIndex = min(max(0, selectedPhaseIndex), groups.count - 1)
                    phaseNavigatorBar(groups: groups, currentIndex: safeIndex)
                    phaseContent(
                        groups: groups,
                        currentIndex: safeIndex,
                        plan: plan,
                        isRoadPlan: isRoadPlan
                    )
                }

            }
            .padding()
        }
        .task(id: plan.id) {
            // Land on the phase containing today on first load (and
            // whenever the plan changes, e.g. after a regeneration).
            selectedPhaseIndex = initialPhaseIndex(plan: plan)
        }
    }

    // MARK: - Phase pagination

    /// All `plan.weeks` grouped contiguously by phase. We page over the
    /// full plan so the athlete can browse every phase even when some
    /// of its weeks are locked behind a subscription, locked phases
    /// surface an upgrade CTA in place of week cards.
    func phaseGroups(plan: TrainingPlan) -> [(phase: TrainingPhase, weeks: [TrainingWeek])] {
        var groups: [(phase: TrainingPhase, weeks: [TrainingWeek])] = []
        for week in plan.weeks {
            if let last = groups.last, last.phase == week.phase {
                groups[groups.count - 1].weeks.append(week)
            } else {
                groups.append((phase: week.phase, weeks: [week]))
            }
        }
        return groups
    }

    /// Index of the phase that contains today's week. Falls back to 0
    /// if no week matches (e.g. plan starts in the future).
    func initialPhaseIndex(plan: TrainingPlan) -> Int {
        let groups = phaseGroups(plan: plan)
        if let idx = groups.firstIndex(where: { group in
            group.weeks.contains(where: { $0.containsToday })
        }) {
            return idx
        }
        return 0
    }

    /// Subset of a phase group's weeks that are currently unlocked for
    /// the athlete's subscription tier.
    private func visibleSubset(of group: (phase: TrainingPhase, weeks: [TrainingWeek])) -> [TrainingWeek] {
        let visibleIds = Set(viewModel.visibleWeeks.map(\.id))
        return group.weeks.filter { visibleIds.contains($0.id) }
    }

    /// Top strip: prev arrow · phase name + progress + dots · next arrow.
    /// Tap to navigate. The dots double as a phase-progress indicator.
    @ViewBuilder
    func phaseNavigatorBar(
        groups: [(phase: TrainingPhase, weeks: [TrainingWeek])],
        currentIndex: Int
    ) -> some View {
        let phase = groups[currentIndex].phase
        let isFirst = currentIndex == 0
        let isLast = currentIndex == groups.count - 1
        HStack(spacing: Theme.Spacing.md) {
            Button {
                guard !isFirst else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedPhaseIndex = currentIndex - 1
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isFirst ? Theme.Colors.tertiaryLabel : phase.color)
            }
            .buttonStyle(.plain)
            .disabled(isFirst)
            .accessibilityLabel("Previous phase")

            VStack(spacing: 4) {
                Text(phase.displayName.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(phase.color)
                Text(String(localized: "tpl.phaseXofY", defaultValue: "Phase \(currentIndex + 1) of \(groups.count)"))
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                HStack(spacing: 5) {
                    ForEach(groups.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentIndex ? groups[i].phase.color : Theme.Colors.tertiaryLabel.opacity(0.3))
                            .frame(width: i == currentIndex ? 14 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                guard !isLast else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedPhaseIndex = currentIndex + 1
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isLast ? Theme.Colors.tertiaryLabel : phase.color)
            }
            .buttonStyle(.plain)
            .disabled(isLast)
            .accessibilityLabel("Next phase")
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(phase.color.opacity(0.25), lineWidth: 0.5)
        )
    }

    /// Phase header + weeks of the selected phase. Slides in from the
    /// trailing edge on next, leading edge on previous. A horizontal
    /// drag gesture mirrors the arrow buttons for swipe navigation;
    /// the drag only fires when the gesture is clearly horizontal so
    /// vertical scroll in the parent ScrollView is preserved.
    @ViewBuilder
    func phaseContent(
        groups: [(phase: TrainingPhase, weeks: [TrainingWeek])],
        currentIndex: Int,
        plan: TrainingPlan,
        isRoadPlan: Bool
    ) -> some View {
        let group = groups[currentIndex]
        let visible = visibleSubset(of: group)
        let lockedCount = group.weeks.count - visible.count
        let completedWeeks = group.weeks.filter { w in
            w.sessions.filter { $0.type != .rest && !$0.isSkipped }.allSatisfy(\.isCompleted)
        }.count
        let firstNum = group.weeks.first?.weekNumber ?? 1
        let lastNum = group.weeks.last?.weekNumber ?? 1

        VStack(spacing: Theme.Spacing.md) {
            PhaseHeaderCard(
                phase: group.phase,
                weekRange: firstNum == lastNum ? String(localized: "wk.week1", defaultValue: "Week \(firstNum)") : String(localized: "wk.weeksRange", defaultValue: "Weeks \(firstNum)-\(lastNum)"),
                completedWeeks: completedWeeks,
                totalWeeks: group.weeks.count,
                description: PhaseHeaderCard.description(
                    for: group.phase,
                    focus: group.weeks.first?.phaseFocus,
                    isRoad: isRoadPlan
                ),
                phaseFocus: group.weeks.first?.phaseFocus,
                isRoad: isRoadPlan
            )

            ForEach(visible) { week in
                let weekIndex = plan.weeks.firstIndex(where: { $0.id == week.id }) ?? 0
                weekCard(
                    week: week,
                    weekIndex: weekIndex,
                    plan: plan,
                    isRoadPlan: isRoadPlan
                )
            }

            if lockedCount > 0 {
                phaseLockedCard(
                    phase: group.phase,
                    lockedCount: lockedCount,
                    isFullyLocked: visible.isEmpty,
                    totalLockedInPlan: viewModel.lockedWeekCount
                )
            }
        }
        .id(currentIndex)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let h = value.translation.width
                    let v = value.translation.height
                    // Horizontal-dominant gesture only, leaves the parent
                    // ScrollView free to handle vertical drags.
                    guard abs(h) > abs(v) * 1.5 else { return }
                    if h > 50, currentIndex > 0 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPhaseIndex = currentIndex - 1
                        }
                    } else if h < -50, currentIndex < groups.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPhaseIndex = currentIndex + 1
                        }
                    }
                }
        )
    }

    /// Single in-phase locked-weeks card that carries BOTH the phase-
    /// specific status and the plan-wide locked total. Replaces what
    /// used to be two stacked cards (one per-phase, one global) so the
    /// athlete reads the locked state in one place per page.
    @ViewBuilder
    func phaseLockedCard(
        phase: TrainingPhase,
        lockedCount: Int,
        isFullyLocked: Bool,
        totalLockedInPlan: Int
    ) -> some View {
        let title: String = {
            if isFullyLocked {
                return String(localized: "tpl.phaseLocked", defaultValue: "\(phase.displayName) phase locked")
            }
            let weekWord = lockedCount == 1
                ? String(localized: "tpl.week", defaultValue: "week")
                : String(localized: "tpl.weeks", defaultValue: "weeks")
            return String(localized: "tpl.moreWeeks", defaultValue: "\(lockedCount) more \(weekWord) in \(phase.displayName)")
        }()
        // Plan-wide total goes in the subtitle (not the title) so the
        // bold phase-line stays on one line at the existing card width.
        let subtitle: String = {
            if totalLockedInPlan > lockedCount {
                return String(localized: "tpl.lockedPlanWide", defaultValue: "\(totalLockedInPlan) locked plan-wide · \(viewModel.lockedWeeksBannerSubtitle)")
            }
            return viewModel.lockedWeeksBannerSubtitle
        }()
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.goldAccent.opacity(0.25), Theme.Colors.goldAccent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(Theme.Colors.goldAccent)
                    .shadow(color: Theme.Colors.goldAccent.opacity(0.4), radius: 3)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Colors.goldAccent.opacity(0.6))
        }
        .futuristicGlassStyle(phaseTint: Theme.Colors.goldAccent)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.goldAccent.opacity(0.2), lineWidth: 1)
        )
        .accessibilityLabel("\(lockedCount) locked weeks in \(phase.displayName) phase, \(totalLockedInPlan) total in plan. Upgrade to view.")
    }

    /// Extracted week-card builder so the phase-pager body stays
    /// readable. Captures the same callbacks the previous flat
    /// ForEach used.
    @ViewBuilder
    private func weekCard(
        week: TrainingWeek,
        weekIndex: Int,
        plan: TrainingPlan,
        isRoadPlan: Bool
    ) -> some View {
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
            stravaActivitiesProvider: viewModel.stravaAuthService?.isConnected() == true ? { date in
                await viewModel.recentStravaActivities(near: date)
            } : nil,
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
            },
            onCompleteFitnessTest: { sessionIndex, variant, result, feeling in
                Task {
                    await viewModel.completeFitnessTestSession(
                        weekIndex: weekIndex,
                        sessionIndex: sessionIndex,
                        variant: variant,
                        result: result,
                        feeling: feeling
                    )
                }
            }
        )
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
                            Text(String(localized: "wk.week", defaultValue: "Week \(currentWeek.weekNumber)"))
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
                Task { await viewModel.prepareToGeneratePlan() }
            },
            isPrimaryLoading: viewModel.isGenerating
        )
        .accessibilityIdentifier("trainingPlan.emptyState")
    }
}
