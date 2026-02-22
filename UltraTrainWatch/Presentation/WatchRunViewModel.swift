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

    // MARK: - Private

    private var trackPoints: [WatchTrackPoint] = []
    private var nutritionReminders: [WatchNutritionReminder] = []
    private var timer: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?
    private var heartRateTask: Task<Void, Never>?
    private var splitDismissTask: Task<Void, Never>?
    private var pausedDuration: TimeInterval = 0
    private var runStartDate: Date?
    private var pauseStartDate: Date?
    private var lastLocation: CLLocation?
    private var lowSpeedDuration: TimeInterval = 0
    private var maxHeartRate: Int?

    private let locationService: WatchLocationService
    private let healthKitService: any WatchHealthKitServiceProtocol
    private let connectivityService: WatchConnectivityService

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

    // MARK: - Private — Timer

    private func startTimer() {
        timer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(WatchConfiguration.Timer.interval))
                guard !Task.isCancelled else { break }
                self?.timerTick()
            }
        }
    }

    private func timerTick() {
        guard runState == .running, let start = runStartDate else { return }
        elapsedTime = Date.now.timeIntervalSince(start) - pausedDuration

        if let pauseStart = pauseStartDate {
            elapsedTime -= Date.now.timeIntervalSince(pauseStart)
        }

        // Update pace
        currentPace = WatchRunCalculator.formatPace(
            WatchRunCalculator.averagePace(distanceKm: distanceKm, duration: elapsedTime)
        )

        // Check nutrition reminders
        if activeReminder == nil {
            activeReminder = WatchNutritionReminderScheduler.nextDueReminder(
                in: nutritionReminders,
                at: elapsedTime
            )
        }
    }

    // MARK: - Private — Location

    private func startLocationTracking() {
        let stream = locationService.startTracking()
        locationTask = Task { [weak self] in
            for await location in stream {
                guard !Task.isCancelled else { break }
                self?.processLocation(location)
            }
        }
    }

    private func processLocation(_ location: CLLocation) {
        guard runState == .running else { return }

        let point = WatchTrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitudeM: location.altitude,
            timestamp: location.timestamp,
            heartRate: currentHeartRate
        )
        trackPoints.append(point)

        // Update distance
        if let last = lastLocation {
            let segmentM = WatchRunCalculator.haversineDistance(
                lat1: last.coordinate.latitude, lon1: last.coordinate.longitude,
                lat2: location.coordinate.latitude, lon2: location.coordinate.longitude
            )
            distanceKm += segmentM / 1000
        }

        // Update elevation
        let changes = WatchRunCalculator.elevationChanges(trackPoints)
        elevationGainM = changes.gainM
        elevationLossM = changes.lossM

        // Check for new km split
        if let newSplit = WatchRunCalculator.liveSplitCheck(
            trackPoints: trackPoints,
            previousSplitCount: splits.count
        ) {
            splits.append(newSplit)
            latestSplit = newSplit
            WKInterfaceDevice.current().play(.notification)
            splitDismissTask?.cancel()
            splitDismissTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                self?.latestSplit = nil
            }
        }

        // Auto-pause detection
        checkAutoPause(speed: location.speed)

        lastLocation = location
    }

    // MARK: - Private — Heart Rate

    private func startHeartRateTracking() {
        let stream = healthKitService.heartRateStream()
        heartRateTask = Task { [weak self] in
            for await hr in stream {
                guard !Task.isCancelled else { break }
                self?.currentHeartRate = hr
                if let maxHR = self?.maxHeartRate {
                    if hr > maxHR { self?.maxHeartRate = hr }
                } else {
                    self?.maxHeartRate = hr
                }
                // Calculate HR zone using athlete data from session
                if let athleteMaxHR = self?.connectivityService.sessionData?.maxHeartRate,
                   let restingHR = self?.connectivityService.sessionData?.restingHeartRate {
                    self?.currentHRZone = WatchHRZoneCalculator.zone(
                        heartRate: hr,
                        maxHR: athleteMaxHR,
                        restingHR: restingHR
                    )
                }
            }
        }
    }

    // MARK: - Private — Auto Pause

    private func checkAutoPause(speed: CLLocationSpeed) {
        guard !isAutoPaused else {
            if speed >= WatchConfiguration.AutoPause.resumeSpeedThreshold {
                resumeRun()
            }
            return
        }

        if speed < WatchConfiguration.AutoPause.pauseSpeedThreshold {
            lowSpeedDuration += WatchConfiguration.Timer.interval
            if lowSpeedDuration >= WatchConfiguration.AutoPause.pauseDelay {
                pauseRun(auto: true)
            }
        } else {
            lowSpeedDuration = 0
        }
    }
}
