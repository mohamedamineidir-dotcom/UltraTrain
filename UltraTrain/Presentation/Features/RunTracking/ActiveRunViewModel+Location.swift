import CoreLocation
import Foundation
import os

// MARK: - Location Tracking & Auto Pause

extension ActiveRunViewModel {

    // MARK: - Location Tracking

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
        if runState == .paused && isAutoPaused {
            handleAutoResume(speed: location.speed)
            return
        }
        guard runState == .running else { return }
        lastKnownSpeed = location.speed >= 0 ? location.speed : 0

        let point = TrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitudeM: location.altitude,
            timestamp: location.timestamp,
            heartRate: currentHeartRate
        )
        trackPoints.append(point)
        routeCoordinates.append(location.coordinate)

        distanceKm = RunStatisticsCalculator.totalDistanceKm(trackPoints)
        let elevation = ElevationCalculator.elevationChanges(trackPoints)
        elevationGainM = elevation.gainM
        elevationLossM = elevation.lossM

        if distanceKm > 0 {
            let pace = RunStatisticsCalculator.averagePace(distanceKm: distanceKm, duration: elapsedTime)
            currentPace = RunStatisticsCalculator.formatPace(pace, unit: athlete.preferredUnit)
            runningAveragePace = pace
        }

        racePacingHandler.processLocation(context: buildPacingContext())

        courseGuidanceHandler?.tick(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            elapsedTime: elapsedTime,
            currentPaceSecondsPerKm: runningAveragePace
        )

        if let handler = courseGuidanceHandler {
            if handler.isOffCourse {
                voiceCoachingHandler.announceOffCourseWarning(
                    distanceM: handler.currentProgress?.distanceOffCourseM ?? 0
                )
            }
            if let arrived = handler.arrivedCheckpoint,
               !arrivedCheckpointIdsForVoice.contains(arrived.id) {
                arrivedCheckpointIdsForVoice.insert(arrived.id)
                voiceCoachingHandler.announceCheckpointArrival(
                    name: arrived.name,
                    timeDelta: handler.arrivedCheckpointTimeDelta
                )
            }
        }

        handleAutoPause(speed: location.speed)
    }

    // MARK: - Heart Rate Streaming

    func startHeartRateStreaming() {
        let stream = healthKitService.startHeartRateStream()
        heartRateTask = Task { [weak self] in
            for await reading in stream {
                guard !Task.isCancelled else { break }
                self?.currentHeartRate = reading.beatsPerMinute
            }
        }
    }

    // MARK: - Auto Pause

    func handleAutoPause(speed: CLLocationSpeed) {
        guard autoPauseEnabled, runState == .running else { return }
        if speed < AppConfiguration.RunTracking.autoPauseSpeedThreshold && speed >= 0 {
            autoPauseTimer += AppConfiguration.RunTracking.timerInterval
            if autoPauseTimer >= AppConfiguration.RunTracking.autoPauseDelay {
                pauseRun(auto: true)
                autoPauseTimer = 0
            }
        } else {
            autoPauseTimer = 0
        }
    }

    func handleAutoResume(speed: CLLocationSpeed) {
        if speed >= AppConfiguration.RunTracking.autoResumeSpeedThreshold {
            resumeRun()
            Logger.tracking.info("Auto-resumed at speed \(speed) m/s")
        }
    }
}
