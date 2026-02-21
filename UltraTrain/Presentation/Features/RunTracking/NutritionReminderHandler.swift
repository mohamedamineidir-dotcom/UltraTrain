import Foundation
import os

@Observable
@MainActor
final class NutritionReminderHandler {

    // MARK: - State

    var nutritionReminders: [NutritionReminder] = []
    var activeReminder: NutritionReminder?
    var favoriteProducts: [NutritionProduct] = []
    var nutritionIntakeLog: [NutritionIntakeEntry] = []
    var liveNutritionTotals: LiveNutritionTracker.Totals?

    // MARK: - Dependencies

    private let nutritionRepository: any NutritionRepository
    private let hapticService: any HapticServiceProtocol
    private let isEnabled: Bool
    private let alertSoundEnabled: Bool
    private let hydrationInterval: TimeInterval
    private let fuelInterval: TimeInterval
    private let electrolyteInterval: TimeInterval
    private let smartRemindersEnabled: Bool

    // MARK: - Private

    private var lastReminderShownTime: [NutritionReminderType: TimeInterval] = [:]
    private var tickCounter: Int = 0

    // MARK: - Context

    struct RunContext: Sendable {
        let elapsedTime: TimeInterval
        let distanceKm: Double
        let currentHeartRate: Int?
        let maxHeartRate: Int
        let runningAveragePace: Double
    }

    // MARK: - Init

    init(
        nutritionRepository: any NutritionRepository,
        hapticService: any HapticServiceProtocol,
        isEnabled: Bool,
        alertSoundEnabled: Bool,
        hydrationInterval: TimeInterval,
        fuelInterval: TimeInterval,
        electrolyteInterval: TimeInterval,
        smartRemindersEnabled: Bool
    ) {
        self.nutritionRepository = nutritionRepository
        self.hapticService = hapticService
        self.isEnabled = isEnabled
        self.alertSoundEnabled = alertSoundEnabled
        self.hydrationInterval = hydrationInterval
        self.fuelInterval = fuelInterval
        self.electrolyteInterval = electrolyteInterval
        self.smartRemindersEnabled = smartRemindersEnabled
    }

    // MARK: - Load

    func loadReminders(raceId: UUID?, linkedSessionId: UUID?) {
        guard isEnabled else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let plan = try await self.nutritionRepository.getNutritionPlan(
                    for: raceId ?? UUID()
                )
                let isGutTraining = plan?.gutTrainingSessionIds.contains(
                    linkedSessionId ?? UUID()
                ) ?? false

                if isGutTraining, let plan {
                    self.nutritionReminders = NutritionReminderScheduler.buildGutTrainingSchedule(from: plan)
                } else {
                    self.nutritionReminders = NutritionReminderScheduler.buildDefaultSchedule(
                        hydrationIntervalSeconds: self.hydrationInterval,
                        fuelIntervalSeconds: self.fuelInterval,
                        electrolyteIntervalSeconds: self.electrolyteInterval
                    )
                }
                Logger.nutrition.info("Loaded \(self.nutritionReminders.count) nutrition reminders")
            } catch {
                self.nutritionReminders = NutritionReminderScheduler.buildDefaultSchedule(
                    hydrationIntervalSeconds: self.hydrationInterval,
                    fuelIntervalSeconds: self.fuelInterval,
                    electrolyteIntervalSeconds: self.electrolyteInterval
                )
                Logger.nutrition.error("Failed to load nutrition plan, using defaults: \(error)")
            }
        }
    }

    func loadFavoriteProducts() {
        guard isEnabled else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let prefs = try await self.nutritionRepository.getNutritionPreferences()
                let allProducts = try await self.nutritionRepository.getProducts()
                let favoriteIds = prefs.favoriteProductIds
                var favorites = favoriteIds.compactMap { fid in allProducts.first { $0.id == fid } }
                if favorites.isEmpty {
                    favorites = Array(allProducts.prefix(4))
                }
                self.favoriteProducts = favorites
            } catch {
                Logger.nutrition.debug("Could not load favorite products: \(error)")
            }
        }
    }

    // MARK: - Tick

    func tick(context: RunContext) {
        checkReminders(context: context)
        tickCounter += 1
        if tickCounter >= 30 {
            tickCounter = 0
            updateTotals(elapsedTime: context.elapsedTime)
        }
    }

    // MARK: - Actions

    func dismiss(elapsedTime: TimeInterval) {
        guard let current = activeReminder else { return }
        logEntry(for: current, status: .pending, elapsedTime: elapsedTime)
        markDismissed(current)
    }

    func markTaken(elapsedTime: TimeInterval) {
        guard let current = activeReminder else { return }
        logEntry(for: current, status: .taken, elapsedTime: elapsedTime)
        markDismissed(current)
        updateTotals(elapsedTime: elapsedTime)
    }

    func markSkipped(elapsedTime: TimeInterval) {
        guard let current = activeReminder else { return }
        logEntry(for: current, status: .skipped, elapsedTime: elapsedTime)
        markDismissed(current)
    }

    func logProduct(_ product: NutritionProduct, elapsedTime: TimeInterval, quantity: Int = 1) {
        let entry = LiveNutritionTracker.buildManualEntry(
            product: product, elapsedTime: elapsedTime, quantity: quantity
        )
        nutritionIntakeLog.append(entry)
        hapticService.playSelection()
        updateTotals(elapsedTime: elapsedTime)
    }

    var nutritionSummary: NutritionIntakeSummary {
        NutritionIntakeSummary(entries: nutritionIntakeLog)
    }

    // MARK: - Private

    private func checkReminders(context: RunContext) {
        guard activeReminder == nil, !nutritionReminders.isEmpty else { return }
        if let next = NutritionReminderScheduler.nextDueReminder(
            in: nutritionReminders, at: context.elapsedTime
        ) {
            if smartRemindersEnabled {
                let adjustedTime = adjustedTriggerTime(for: next, context: context)
                guard context.elapsedTime >= adjustedTime else { return }
            }
            activeReminder = next
            lastReminderShownTime[next.type] = context.elapsedTime
            if alertSoundEnabled {
                hapticService.playNutritionAlert()
            }
        }
    }

    private func adjustedTriggerTime(
        for reminder: NutritionReminder,
        context: RunContext
    ) -> TimeInterval {
        let conditions = AdaptiveReminderAdjuster.RunConditions(
            currentHeartRate: context.currentHeartRate,
            maxHeartRate: context.maxHeartRate,
            elapsedDistanceKm: context.distanceKm,
            currentPaceSecondsPerKm: context.distanceKm > 0 ? context.elapsedTime / context.distanceKm : nil,
            averagePaceSecondsPerKm: context.runningAveragePace > 0 ? context.runningAveragePace : nil
        )
        let multiplier = AdaptiveReminderAdjuster.intervalMultiplier(
            for: reminder.type, conditions: conditions
        )
        let baseInterval = reminder.triggerTimeSeconds - (lastReminderShownTime[reminder.type] ?? 0)
        let adjustedInterval = baseInterval * multiplier
        return (lastReminderShownTime[reminder.type] ?? 0) + adjustedInterval
    }

    private func logEntry(
        for reminder: NutritionReminder,
        status: NutritionIntakeStatus,
        elapsedTime: TimeInterval
    ) {
        let entry = NutritionIntakeEntry(
            reminderType: reminder.type,
            status: status,
            elapsedTimeSeconds: elapsedTime,
            message: reminder.message
        )
        nutritionIntakeLog.append(entry)
    }

    private func markDismissed(_ reminder: NutritionReminder) {
        if let index = nutritionReminders.firstIndex(where: { $0.id == reminder.id }) {
            nutritionReminders[index].isDismissed = true
        }
        activeReminder = nil
    }

    private func updateTotals(elapsedTime: TimeInterval) {
        liveNutritionTotals = LiveNutritionTracker.calculateTotals(
            from: nutritionIntakeLog, elapsedTime: elapsedTime
        )
    }
}
