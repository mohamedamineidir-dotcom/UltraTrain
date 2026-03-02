import CoreLocation
import os
import WatchKit

// MARK: - Timer, Location, Heart Rate & Auto-Pause Tracking

extension WatchRunViewModel {

    // MARK: - Timer

    func startTimer() {
        timer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(WatchConfiguration.Timer.interval))
                guard !Task.isCancelled else { break }
                self?.timerTick()
            }
        }
    }

    func timerTick() {
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

    // MARK: - Location

    func startLocationTracking() {
        let stream = locationService.startTracking()
        locationTask = Task { [weak self] in
            for await location in stream {
                guard !Task.isCancelled else { break }
                self?.processLocation(location)
            }
        }
    }

    func processLocation(_ location: CLLocation) {
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

    // MARK: - Heart Rate

    func startHeartRateTracking() {
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

    // MARK: - Auto Pause

    func checkAutoPause(speed: CLLocationSpeed) {
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
