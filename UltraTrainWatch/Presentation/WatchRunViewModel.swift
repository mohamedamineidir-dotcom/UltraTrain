import CoreLocation
import os
import WatchKit

enum WatchRunState: String, Sendable {
    case notStarted
    case running
    case paused
    case finished
}

@Observable
@MainActor
final class WatchRunViewModel {

    // MARK: - State

    var runState: WatchRunState = .notStarted
    var elapsedTime: TimeInterval = 0
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var currentPace: String = "--:--"
    var currentHeartRate: Int?
    var isAutoPaused = false
    var activeReminder: WatchNutritionReminder?
    var splits: [WatchSplit] = []
    var latestSplit: WatchSplit?
    var currentHRZone: Int?
    var error: String?

    var linkedSession: WatchSessionData?

    var formattedTime: String {
        WatchRunCalculator.formatDuration(elapsedTime)
    }

    var formattedDistance: String {
        String(format: "%.2f", distanceKm)
    }

    var formattedElevation: String {
        "+\(Int(elevationGainM)) m"
    }

    // MARK: - Internal (accessed by extension)

    var trackPoints: [WatchTrackPoint] = []
    var nutritionReminders: [WatchNutritionReminder] = []
    var timer: Task<Void, Never>?
    var locationTask: Task<Void, Never>?
    var heartRateTask: Task<Void, Never>?
    var splitDismissTask: Task<Void, Never>?
    var pausedDuration: TimeInterval = 0
    var runStartDate: Date?
    var pauseStartDate: Date?
    var lastLocation: CLLocation?
    var lowSpeedDuration: TimeInterval = 0
    var maxHeartRate: Int?

    let locationService: WatchLocationService
    let healthKitService: any WatchHealthKitServiceProtocol
    let connectivityService: WatchConnectivityService

    // MARK: - Init

    init(
        locationService: WatchLocationService,
        healthKitService: any WatchHealthKitServiceProtocol,
        connectivityService: WatchConnectivityService
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.connectivityService = connectivityService
    }

    // MARK: - Run Lifecycle

    func startRun() async {
        guard runState == .notStarted else { return }

        do {
            try await healthKitService.startWorkoutSession()
        } catch {
            Logger.watch.error("Failed to start workout session: \(error)")
            self.error = "Could not start workout session"
            return
        }

        runState = .running
        runStartDate = .now
        nutritionReminders = WatchNutritionReminderScheduler.buildDefaultSchedule()

        startTimer()
        startLocationTracking()
        startHeartRateTracking()

        Logger.watch.info("Watch standalone run started")
    }

    func pauseRun(auto: Bool = false) {
        guard runState == .running else { return }
        runState = .paused
        isAutoPaused = auto
        pauseStartDate = .now

        locationService.pauseTracking()
        healthKitService.pauseWorkoutSession()

        Logger.watch.info("Watch run paused (auto: \(auto))")
    }

    func resumeRun() {
        guard runState == .paused else { return }

        if let pauseStart = pauseStartDate {
            pausedDuration += Date.now.timeIntervalSince(pauseStart)
        }
        pauseStartDate = nil
        isAutoPaused = false
        lowSpeedDuration = 0

        runState = .running
        locationService.resumeTracking()
        healthKitService.resumeWorkoutSession()

        Logger.watch.info("Watch run resumed")
    }

    func stopRun() async {
        guard runState == .running || runState == .paused else { return }

        if runState == .paused, let pauseStart = pauseStartDate {
            pausedDuration += Date.now.timeIntervalSince(pauseStart)
        }

        runState = .finished
        timer?.cancel()
        timer = nil
        locationTask?.cancel()
        locationTask = nil
        heartRateTask?.cancel()
        heartRateTask = nil
        splitDismissTask?.cancel()
        splitDismissTask = nil

        locationService.stopTracking()
        do {
            try await healthKitService.stopWorkoutSession()
        } catch {
            Logger.watch.error("Failed to stop workout session: \(error)")
        }

        Logger.watch.info("Watch run stopped — \(self.formattedDistance) km in \(self.formattedTime)")
    }

    // MARK: - Nutrition

    func dismissReminder() {
        guard let active = activeReminder else { return }
        if let index = nutritionReminders.firstIndex(where: { $0.id == active.id }) {
            nutritionReminders[index].isDismissed = true
        }
        activeReminder = nil
    }

    // MARK: - Sync

    func buildCompletedRunData() -> WatchCompletedRunData {
        let heartRates = trackPoints.compactMap(\.heartRate)
        let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count

        return WatchCompletedRunData(
            runId: UUID(),
            date: runStartDate ?? .now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            duration: elapsedTime,
            pausedDuration: pausedDuration,
            averageHeartRate: avgHR,
            maxHeartRate: maxHeartRate,
            averagePaceSecondsPerKm: WatchRunCalculator.averagePace(
                distanceKm: distanceKm,
                duration: elapsedTime
            ),
            trackPoints: trackPoints,
            splits: WatchRunCalculator.buildSplits(from: trackPoints),
            linkedSessionId: linkedSession?.sessionId
        )
    }

    func syncCompletedRun() {
        let data = buildCompletedRunData()
        connectivityService.sendCompletedRun(data)
    }
}
