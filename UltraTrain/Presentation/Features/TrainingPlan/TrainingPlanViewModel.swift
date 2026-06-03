import Foundation
import os

@Observable
@MainActor
final class TrainingPlanViewModel {

    // MARK: - Dependencies

    let planRepository: any TrainingPlanRepository
    let athleteRepository: any AthleteRepository
    let raceRepository: any RaceRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    let nutritionAdvisor: any SessionNutritionAdvisor
    let fitnessRepository: any FitnessRepository
    /// Optional. When provided, the latest RecoveryScore is fetched on
    /// plan load and passed to PlanAdjustmentCalculator.analyze. That
    /// fires the swapToRecoveryLowRecovery / reduceLoadLowRecovery
    /// recommendations which Commit E added to the urgent auto-apply
    /// set, turning poor overnight HRV/sleep into an automatic swap
    /// of today's hard session for an easy run, no banner round-trip.
    let recoveryRepository: (any RecoveryRepository)?
    let widgetDataWriter: WidgetDataWriter
    private let hapticService: any HapticServiceProtocol
    private let subscriptionService: (any SubscriptionServiceProtocol)?
    let runRepository: (any RunRepository)?
    let stravaAuthService: (any StravaAuthServiceProtocol)?
    let stravaImportService: (any StravaImportServiceProtocol)?
    let intervalPerformanceRepository: (any IntervalPerformanceRepository)?
    /// #27: lets the plan viewmodel keep scheduled training reminders
    /// in sync when sessions are swapped, rescheduled, skipped, or the
    /// plan is regenerated. Optional for callers that don't care about
    /// reminders; nil-safe throughout.
    let notificationService: (any NotificationServiceProtocol)?
    let appSettingsRepository: (any AppSettingsRepository)?

    // MARK: - State

    var plan: TrainingPlan?
    var races: [Race] = []
    var athlete: Athlete?
    var nutritionPreferences: NutritionPreferences = .default
    var isLoading = false
    var isGenerating = false
    var error: String?
    var showRegenerateConfirmation = false
    var subscriptionStatus: SubscriptionStatus?
    var adjustmentRecommendations: [PlanAdjustmentRecommendation] = []
    var dismissedRecommendationIds: Set<UUID> = []
    var isApplyingAdjustment = false
    /// #22: next-7-day injury-risk projection (ACWR + monotony).
    /// Recomputed whenever the plan reloads or regenerates.
    var injuryRiskProjection: PlanInjuryRiskProjector.Projection?
    /// Session-scoped dismissal for the banner, athlete can hide it
    /// for the current app session without disabling projection.
    var injuryRiskBannerDismissed: Bool = false
    /// #26: sustained-missed-session pattern (skips / quality drift /
    /// inactivity). Recomputed on plan load + session mutations.
    var missedSessionPattern: MissedSessionPatternDetector.Pattern?
    var missedSessionBannerDismissed: Bool = false

    // MARK: - Init

    init(
        planRepository: any TrainingPlanRepository,
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionAdvisor: any SessionNutritionAdvisor,
        fitnessRepository: any FitnessRepository,
        widgetDataWriter: WidgetDataWriter,
        hapticService: any HapticServiceProtocol,
        subscriptionService: (any SubscriptionServiceProtocol)? = nil,
        runRepository: (any RunRepository)? = nil,
        stravaAuthService: (any StravaAuthServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        intervalPerformanceRepository: (any IntervalPerformanceRepository)? = nil,
        notificationService: (any NotificationServiceProtocol)? = nil,
        appSettingsRepository: (any AppSettingsRepository)? = nil,
        recoveryRepository: (any RecoveryRepository)? = nil
    ) {
        self.planRepository = planRepository
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planGenerator = planGenerator
        self.nutritionRepository = nutritionRepository
        self.nutritionAdvisor = nutritionAdvisor
        self.fitnessRepository = fitnessRepository
        self.widgetDataWriter = widgetDataWriter
        self.hapticService = hapticService
        self.subscriptionService = subscriptionService
        self.runRepository = runRepository
        self.stravaAuthService = stravaAuthService
        self.stravaImportService = stravaImportService
        self.intervalPerformanceRepository = intervalPerformanceRepository
        self.notificationService = notificationService
        self.appSettingsRepository = appSettingsRepository
        self.recoveryRepository = recoveryRepository
    }

    // MARK: - Load

    func loadPlan() async {
        isLoading = true
        error = nil

        // Refresh subscription status first, the active-plan resolution
        // (which plan to surface, and whether it's locked) depends on tier.
        subscriptionStatus = await subscriptionService?.refreshStatus()

        do {
            races = try await raceRepository.getRaces()
            athlete = try await athleteRepository.getAthlete()
            nutritionPreferences = try await nutritionRepository.getNutritionPreferences()
            await resolveActivePlan()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load plan: \(error)")
        }

        isLoading = false
        checkForAdjustments()
        refreshInjuryRiskProjection()
        refreshMissedSessionPattern()
        refreshScheduledReminders()
    }

    /// Picks which preserved plan to surface based on tier, and whether it's
    /// locked. Premium: restore the custom plan as active (a free scenario,
    /// if any, stays archived). Free: keep the active plan, a custom plan
    /// there is shown locked; once the user starts a free scenario it becomes
    /// active and the custom is archived (preserved for resubscribe).
    func resolveActivePlan() async {
        do {
            let all = try await planRepository.getAllPlans()
            let customPlan = all.first { !$0.isScenarioPlan }

            if !isFreeTier,
               let customPlan,
               let active = all.first(where: { !$0.isArchived }),
               active.isScenarioPlan {
                // Re-subscribed: bring the preserved custom plan back as active.
                try await planRepository.setActivePlan(id: customPlan.id)

                // If the race is still ahead but the athlete was away a while,
                // offer the comeback questionnaire to re-periodize. (A passed
                // race is handled by the expired-plan state instead.)
                let raceAhead = (customPlan.weeks.last?.endDate ?? .distantPast) >= .now
                let weeks = weeksSinceLastCompletedSession(customPlan)
                if raceAhead, weeks >= 2 {
                    comebackWeeksAway = weeks
                    showComebackSheet = true
                }
            }

            plan = try await planRepository.getActivePlan()
            hasPreservedCustomPlan = customPlan != nil
            isCustomPlanLocked = isFreeTier && (plan.map { !$0.isScenarioPlan } ?? false)
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to resolve active plan: \(error)")
        }
    }

    /// Weeks since the athlete last completed a session in this plan, used to
    /// size the comeback adjustment. 0 when nothing has been completed.
    private func weeksSinceLastCompletedSession(_ plan: TrainingPlan) -> Int {
        let lastDate = plan.weeks
            .flatMap { $0.sessions }
            .filter { $0.isCompleted }
            .map { $0.date }
            .max()
        guard let lastDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0
        return max(0, days / 7)
    }

    /// Answers the comeback questionnaire: compute a detraining-aware
    /// adjustment (volume damper + easy-only weeks) and regenerate the plan
    /// re-anchored to today. "Kept training" yields no adjustment.
    func applyComeback(_ gapLevel: GapTrainingLevel) async {
        showComebackSheet = false
        guard let athlete else { await generatePlan(); return }
        let race = targetRace
        let raceDistance = race?.distanceKm ?? plan?.weeks.first?.sessions.first?.plannedDistanceKm ?? 21.1
        let weeksUntil = race.map { max(1, Date.now.startOfDay.weeksBetween($0.date.startOfDay)) }
            ?? max(1, (plan?.weeks.count ?? 12))

        let adjustment = ComebackAdjustmentCalculator.compute(
            gapLevel: gapLevel,
            weeksAway: comebackWeeksAway,
            experience: athlete.experienceLevel,
            raceDistanceKm: raceDistance,
            weeksUntilRace: weeksUntil
        )
        pendingPlanOptions = PlanGenerationOptions(
            includeFitnessTest: false,
            recentFitnessChange: adjustment.fitnessChange == .none ? nil : adjustment.fitnessChange,
            comebackEasyOnlyWeeks: adjustment.easyOnlyWeeks
        )
        await generatePlan()
    }

    /// Recomputes the next-7-day injury-risk projection from the
    /// currently-loaded plan. Cheap (pure domain computation), safe
    /// to call any time the plan changes.
    func refreshInjuryRiskProjection() {
        guard let plan else {
            injuryRiskProjection = nil
            return
        }
        injuryRiskProjection = PlanInjuryRiskProjector.project(plan: plan)
    }

    /// #26: recomputes the trailing 14-day missed-session pattern.
    /// Cheap pure-domain scan, safe to call after any mutation.
    /// Dismissal state is intentionally NOT reset by refresh so the
    /// athlete doesn't re-see the same banner on every plan edit in
    /// the same app session.
    func refreshMissedSessionPattern() {
        guard let plan else {
            missedSessionPattern = nil
            return
        }
        missedSessionPattern = MissedSessionPatternDetector.detect(plan: plan)
    }

    var shouldShowMissedSessionBanner: Bool {
        !missedSessionBannerDismissed && missedSessionPattern != nil
    }

    /// True when we have a non-empty flag set AND the athlete hasn't
    /// dismissed the banner this session. Banner view consults this
    /// to decide whether to render.
    var shouldShowInjuryRiskBanner: Bool {
        guard !injuryRiskBannerDismissed,
              let projection = injuryRiskProjection else { return false }
        return !projection.flags.isEmpty
    }

    // MARK: - Refresh Races

    func refreshRaces() async {
        do {
            races = try await raceRepository.getRaces()
        } catch {
            Logger.training.error("Failed to refresh races: \(error)")
        }
    }

    // MARK: - Generate

    /// Plan-time options collected from the small onboarding sheet.
    /// Set by `PlanGenerationOptionsSheet.onGenerate`. Reset to standard
    /// after each plan generation so the next regen starts fresh.
    var pendingPlanOptions: PlanGenerationOptions = .standard

    /// Most recent fitness-test recalibration outcome. Drives a
    /// post-test recommendation banner / sheet so the athlete sees
    /// the rationale for any pace updates.
    var fitnessTestRecommendation: FitnessTestRecommendation?

    struct FitnessTestRecommendation: Equatable, Sendable, Identifiable {
        let id = UUID()
        let variant: FitnessTestVariant
        let outcome: FitnessTestRecalibrator.Result
    }

    /// Drives the plan-options sheet presentation. The view binds to
    /// this; call `prepareToGeneratePlan()` to load the inputs and
    /// flip it on.
    var showPlanOptionsSheet: Bool = false

    /// Inputs the plan-options sheet needs. Populated by
    /// `prepareToGeneratePlan()` before the sheet is shown.
    private(set) var planOptionsSheetAthlete: Athlete?
    private(set) var planOptionsSheetTargetRace: Race?
    private(set) var planOptionsSheetTotalWeeks: Int = 0

    /// Free-tier scenario picker (comeback / 5K) shown instead of the
    /// custom-race options sheet for free users.
    var showPlanScenarioSheet: Bool = false

    /// Comeback questionnaire shown when a premium custom plan is restored
    /// after a real gap (race still ahead). Drives a re-periodized,
    /// detraining-aware regeneration.
    var showComebackSheet: Bool = false
    /// Weeks since the athlete last completed a session, fed to the comeback
    /// adjustment.
    var comebackWeeksAway: Int = 0
    /// Scenario selected by a free user; drives the next `generatePlan()`.
    var pendingScenario: FreePlanScenario?

    /// True when the surfaced plan is a custom (premium) plan being shown to
    /// a free user, render it locked (resubscribe to continue) and offer a
    /// free plan instead. The plan + its progress are preserved, not deleted.
    var isCustomPlanLocked = false
    /// True when a custom plan is preserved in storage (active-but-locked, or
    /// archived behind a free scenario plan). Drives the "your race plan is
    /// saved, resubscribe" banner.
    var hasPreservedCustomPlan = false

    /// True when the active plan's whole window is already in the past, e.g.
    /// the athlete paused (or cancelled), came back, and the race they were
    /// preparing for has now gone by. The plan can't just resume, they need
    /// a fresh goal.
    var isActivePlanExpired: Bool {
        guard let plan, let lastEnd = plan.weeks.last?.endDate else { return false }
        return lastEnd < Date.now
    }

    /// Saves a freshly-chosen race and regenerates the plan around it. Used
    /// from the expired-plan state to set up a new goal.
    func setUpNewRace(_ race: Race) async {
        do {
            try await raceRepository.saveRace(race)
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to save new race: \(error)")
        }
        await generatePlan()
    }

    /// True only when we KNOW the user is on the free tier (status loaded
    /// and inactive). Unknown / loading defaults to premium so we never
    /// wrongly restrict a paying user.
    var isFreeTier: Bool {
        #if DEBUG
        if DebugEntitlement.simulateFreeTier { return true }
        #endif
        return !(subscriptionStatus?.isActive ?? true)
    }

    /// Loads the athlete + target race + plan length so the sheet has
    /// everything it needs, then presents it. Called by the view when
    /// the user taps "Generate plan" / "Update plan". Falls back to
    /// direct generation (skipping the sheet) when the prerequisites
    /// can't be loaded, better than blocking the user.
    func prepareToGeneratePlan() async {
        // Free tier: no custom race options, pick one of the two fixed
        // scenarios (comeback / 5K) instead.
        if isFreeTier {
            showPlanScenarioSheet = true
            return
        }
        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                await generatePlan()
                return
            }
            let allRaces = try await raceRepository.getRaces()
            let aRacesByDate = allRaces
                .filter { $0.priority == .aRace }
                .sorted { $0.date < $1.date }
            let target = aRacesByDate.last ?? Race.generalFitness(startingFrom: .now)
            let totalWeeks = max(1, Date.now.startOfDay.weeksBetween(target.date.startOfDay))
            planOptionsSheetAthlete = athlete
            planOptionsSheetTargetRace = target
            planOptionsSheetTotalWeeks = totalWeeks
            showPlanOptionsSheet = true
        } catch {
            Logger.training.error("prepareToGeneratePlan failed: \(error). Falling back to direct generation.")
            await generatePlan()
        }
    }

    /// Sets the pending options + triggers generation. Called from
    /// `PlanGenerationOptionsSheet.onGenerate`.
    func generatePlanWithOptions(_ options: PlanGenerationOptions) async {
        pendingPlanOptions = options
        showPlanOptionsSheet = false
        await generatePlan()
    }

    /// Free-tier path: generate one of the two fixed 12-week scenario
    /// plans. Called from the scenario picker.
    func generateScenarioPlan(_ scenario: FreePlanScenario) async {
        pendingScenario = scenario
        showPlanScenarioSheet = false
        await generatePlan()
    }

    func generatePlan() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil
        let generationStart = ContinuousClock.now

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                throw DomainError.athleteNotFound
            }

            let allRaces = try await raceRepository.getRaces()
            // Free-tier scenario plan: synthetic 12-week comeback / 5K race,
            // no intermediate races. Otherwise the normal custom-race path.
            let scenario = pendingScenario
            let targetRace: Race
            let intermediateRaces: [Race]
            if let scenario {
                targetRace = Race.scenarioRace(for: scenario)
                intermediateRaces = []
            } else {
                // Two-A-race seasons: target is the LATEST A-race; earlier
                // A-races flow through IntermediateRaceHandler with full
                // 2-week taper + 2-3 week recovery.
                let aRacesByDate = allRaces
                    .filter { $0.priority == .aRace }
                    .sorted { $0.date < $1.date }
                targetRace = aRacesByDate.last ?? Race.generalFitness(startingFrom: .now)
                intermediateRaces = allRaces.filter { race in
                    race.id != targetRace.id && race.date < targetRace.date
                }
            }

            // Snapshot old session progress before regenerating
            let oldProgress = plan.map { PlanProgressPreserver.snapshot($0) } ?? []

            // IR-2: load recent interval / tempo feedback so the generator
            // can refine target paces if evidence warrants it. Silent
            // failure, the generator falls back to pure fitness-derived
            // paces when feedback can't be loaded.
            let recentFeedback = await loadRecentIntervalFeedback()

            // Options from the plan-time sheet (fitness test opt-in,
            // recent fitness change). Reset to standard after to avoid
            // leaking state into a future regen.
            let options = pendingPlanOptions
            pendingPlanOptions = .standard

            var newPlan = try await planGenerator.execute(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces,
                recentIntervalFeedback: recentFeedback,
                planOptions: options
            )
            // Mark + clear scenario state. Scenario plans stay fully visible
            // regardless of subscription (free taster).
            newPlan.isScenarioPlan = scenario != nil
            pendingScenario = nil

            // Comeback "volume before intensity": soften the first N upcoming
            // weeks' quality to easy aerobic (the generator already dampened
            // volume via recentFitnessChange).
            ComebackPlanAdjuster.softenEarlyQuality(
                in: &newPlan, easyOnlyWeeks: options.comebackEasyOnlyWeeks
            )

            // Restore progress from old plan to matching sessions
            PlanProgressPreserver.restore(oldProgress, into: &newPlan)

            try await planRepository.savePlan(newPlan)

            // Persist restored session statuses
            for week in newPlan.weeks {
                for session in week.sessions where session.isCompleted || session.isSkipped || session.linkedRunId != nil {
                    try await planRepository.updateSession(session)
                }
            }

            plan = newPlan
            self.athlete = athlete
            races = allRaces
            refreshInjuryRiskProjection()
            refreshMissedSessionPattern()
            // Clear dismissal state when regenerating, the new plan
            // deserves a fresh review if any pattern persists.
            missedSessionBannerDismissed = false
            refreshScheduledReminders()
            Logger.training.info("Plan generated: \(newPlan.weeks.count) weeks")
            hapticService.playSuccess()
            await updateWidgets()
            checkForAdjustments()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to generate plan: \(error)")
        }

        // Let the loading animation finish its current cycle (~8.5s total)
        let elapsed = ContinuousClock.now - generationStart
        let minimumDuration = Duration.seconds(8.5)
        if elapsed < minimumDuration {
            try? await Task.sleep(for: minimumDuration - elapsed)
        }

        isGenerating = false
    }

    // MARK: - Subscription-based Visibility

    var visibleWeeks: [TrainingWeek] {
        guard let plan else { return [] }

        // Free-tier scenario plans (comeback / 5K) are the taster, always
        // fully visible regardless of subscription. The week-window gate
        // below only applies to custom plans.
        if plan.isScenarioPlan { return plan.weeks }

        // No subscription service → show all (e.g. debug/dev)
        guard let status = subscriptionStatus else { return plan.weeks }

        // Free trial → show first 3 weeks as a preview
        if status.isInTrialPeriod {
            return Array(plan.weeks.prefix(3))
        }

        // Inactive subscription → teaser (first week only)
        guard status.isActive else {
            return Array(plan.weeks.prefix(1))
        }

        guard let period = status.period else { return plan.weeks }

        switch period {
        case .yearly:
            return plan.weeks
        case .monthly:
            return weeksInWindow(plan: plan, futureWeekCount: 4)
        case .quarterly:
            return weeksInWindow(plan: plan, futureWeekCount: 12)
        }
    }

    var hasLockedWeeks: Bool {
        guard let plan else { return false }
        return visibleWeeks.count < plan.weeks.count
    }

    var lockedWeekCount: Int {
        guard let plan else { return 0 }
        return plan.weeks.count - visibleWeeks.count
    }

    var lockedWeeksBannerSubtitle: String {
        "Upgrade your plan or wait for your subscription to renew"
    }

    private func weeksInWindow(plan: TrainingPlan, futureWeekCount: Int) -> [TrainingWeek] {
        guard let currentIndex = plan.weeks.firstIndex(where: { $0.containsToday }) else {
            // Before plan start → show first (futureWeekCount + 1) weeks
            return Array(plan.weeks.prefix(futureWeekCount + 1))
        }
        let endIndex = min(currentIndex + futureWeekCount + 1, plan.weeks.count)
        return Array(plan.weeks[0..<endIndex])
    }

    // MARK: - Computed

    var currentWeek: TrainingWeek? {
        plan?.weeks.first { $0.containsToday }
    }

    var nextSession: TrainingSession? {
        guard let week = currentWeek else { return nil }
        let now = Date.now.startOfDay
        return week.sessions
            .filter { !$0.isCompleted && !$0.isSkipped && $0.date >= now && $0.type != .rest }
            .sorted { $0.date < $1.date }
            .first
    }

    var weeklyProgress: (completed: Int, total: Int) {
        guard let week = currentWeek else { return (0, 0) }
        let activeSessions = week.sessions.filter { $0.type != .rest && !$0.isSkipped }
        let completed = activeSessions.filter(\.isCompleted).count
        return (completed, activeSessions.count)
    }

    var targetRace: Race? {
        races.first { $0.priority == .aRace }
    }

    var isPlanStale: Bool {
        guard let plan else { return false }
        // Free scenario plans are intentionally not tied to the athlete's
        // A-race, so a dormant onboarding race shouldn't flag them stale.
        if plan.isScenarioPlan { return false }
        // If user added an A-race after generating a no-race plan, mark stale
        if let target = targetRace, plan.targetRaceId != target.id {
            return true
        }
        guard let target = targetRace else { return false }
        let currentIntermediates = races
            .filter { $0.priority != .aRace && $0.date < target.date }

        // Use snapshots for comparison when available (detects date + priority changes)
        if !plan.intermediateRaceSnapshots.isEmpty {
            let currentSnapshots = currentIntermediates
                .map { RaceSnapshot(id: $0.id, date: $0.date, priority: $0.priority) }
                .sorted { $0.id.uuidString < $1.id.uuidString }
            let planSnapshots = plan.intermediateRaceSnapshots
                .sorted { $0.id.uuidString < $1.id.uuidString }
            return currentSnapshots != planSnapshots
        }

        // Fallback for old plans without snapshots, UUID-only comparison
        let currentIds = currentIntermediates
            .map(\.id)
            .sorted { $0.uuidString < $1.uuidString }
        let planIds = plan.intermediateRaceIds
            .sorted { $0.uuidString < $1.uuidString }
        return currentIds != planIds
    }

    var raceChangeSummary: (added: [Race], removed: [UUID]) {
        guard let plan, let target = targetRace else { return ([], []) }
        let currentIntermediates = races.filter { $0.priority != .aRace && $0.date < target.date }
        let currentIds = Set(currentIntermediates.map(\.id))
        let planIds = Set(plan.intermediateRaceIds)

        let added = currentIntermediates.filter { !planIds.contains($0.id) }
        let removed = plan.intermediateRaceIds.filter { !currentIds.contains($0) }
        return (added, removed)
    }

    // MARK: - Widgets

    func updateWidgets() async {
        await widgetDataWriter.writeNextSession()
        await widgetDataWriter.writeWeeklyProgress()
        widgetDataWriter.reloadWidgets()
    }
}
