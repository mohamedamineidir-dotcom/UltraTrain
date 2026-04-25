import Foundation
import os

@Observable
@MainActor
final class TrainingPlanViewModel {

    // MARK: - Dependencies

    let planRepository: any TrainingPlanRepository
    let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    let nutritionAdvisor: any SessionNutritionAdvisor
    let fitnessRepository: any FitnessRepository
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
    /// Session-scoped dismissal for the banner — athlete can hide it
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
        appSettingsRepository: (any AppSettingsRepository)? = nil
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
    }

    // MARK: - Load

    func loadPlan() async {
        isLoading = true
        error = nil

        do {
            plan = try await planRepository.getActivePlan()
            races = try await raceRepository.getRaces()
            athlete = try await athleteRepository.getAthlete()
            nutritionPreferences = try await nutritionRepository.getNutritionPreferences()
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load plan: \(error)")
        }

        subscriptionStatus = await subscriptionService?.refreshStatus()

        isLoading = false
        checkForAdjustments()
        refreshInjuryRiskProjection()
        refreshMissedSessionPattern()
        refreshScheduledReminders()
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
    /// Cheap pure-domain scan — safe to call after any mutation.
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
            let targetRace = allRaces.first(where: { $0.priority == .aRace })
                ?? Race.generalFitness(startingFrom: .now)

            let intermediateRaces = allRaces.filter { $0.priority != .aRace && $0.date < targetRace.date }

            // Snapshot old session progress before regenerating
            let oldProgress = plan.map { PlanProgressPreserver.snapshot($0) } ?? []

            // IR-2: load recent interval / tempo feedback so the generator
            // can refine target paces if evidence warrants it. Silent
            // failure — the generator falls back to pure fitness-derived
            // paces when feedback can't be loaded.
            let recentFeedback = await loadRecentIntervalFeedback()

            var newPlan = try await planGenerator.execute(
                athlete: athlete,
                targetRace: targetRace,
                intermediateRaces: intermediateRaces,
                recentIntervalFeedback: recentFeedback
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
            // Clear dismissal state when regenerating — the new plan
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
        "Upgrade your plan to see more, or wait for your subscription to renew"
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

        // Fallback for old plans without snapshots — UUID-only comparison
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
