import Foundation
import CoreLocation
import os

enum RunState: Equatable {
    case notStarted
    case running
    case paused
    case finished
}

@Observable
@MainActor
final class ActiveRunViewModel {

    // MARK: - Dependencies

    private let locationService: LocationService
    private let healthKitService: any HealthKitServiceProtocol
    private let runRepository: any RunRepository
    private let planRepository: any TrainingPlanRepository

    // MARK: - Config

    let athlete: Athlete
    let linkedSession: TrainingSession?

    // MARK: - State

    var runState: RunState = .notStarted
    var elapsedTime: TimeInterval = 0
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var currentPace: String = "--:--"
    var currentHeartRate: Int?
    var trackPoints: [TrackPoint] = []
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var error: String?
    var showSummary = false
    var isSaving = false

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?
    private var heartRateTask: Task<Void, Never>?
    private var autoPauseTimer: TimeInterval = 0

    // MARK: - Init

    init(
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        athlete: Athlete,
        linkedSession: TrainingSession?
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.athlete = athlete
        self.linkedSession = linkedSession
    }

    // MARK: - Controls

    func startRun() {
        runState = .running
        startTimer()
        startLocationTracking()
        startHeartRateStreaming()
        Logger.tracking.info("Run started")
    }

    func pauseRun() {
        guard runState == .running else { return }
        runState = .paused
        timerTask?.cancel()
        locationService.pauseTracking()
        Logger.tracking.info("Run paused at \(self.elapsedTime)s")
    }

    func resumeRun() {
        guard runState == .paused else { return }
        runState = .running
        startTimer()
        locationService.resumeTracking()
        Logger.tracking.info("Run resumed")
    }

    func stopRun() {
        runState = .finished
        timerTask?.cancel()
        locationTask?.cancel()
        heartRateTask?.cancel()
        locationService.stopTracking()
        healthKitService.stopHeartRateStream()
        showSummary = true
        Logger.tracking.info("Run stopped — \(self.distanceKm) km in \(self.elapsedTime)s")
    }

    // MARK: - Save

    func saveRun(notes: String?) async {
        isSaving = true
        let splits = RunStatisticsCalculator.buildSplits(from: trackPoints)
        let heartRates = trackPoints.compactMap(\.heartRate)
        let avgHR = heartRates.isEmpty ? nil : heartRates.reduce(0, +) / heartRates.count
        let maxHR = heartRates.max()
        let pace = RunStatisticsCalculator.averagePace(
            distanceKm: distanceKm, duration: elapsedTime
        )

        let run = CompletedRun(
            id: UUID(),
            athleteId: athlete.id,
            date: Date.now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: elevationLossM,
            duration: elapsedTime,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            averagePaceSecondsPerKm: pace,
            gpsTrack: trackPoints,
            splits: splits,
            linkedSessionId: linkedSession?.id,
            notes: notes
        )

        do {
            try await runRepository.saveRun(run)
            if let session = linkedSession {
                var updated = session
                updated.isCompleted = true
                updated.linkedRunId = run.id
                try await planRepository.updateSession(updated)
            }
            Logger.tracking.info("Run saved: \(run.id)")
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to save run: \(error)")
        }
        isSaving = false
    }

    func discardRun() {
        Logger.tracking.info("Run discarded")
    }

    // MARK: - Computed

    var formattedTime: String {
        RunStatisticsCalculator.formatDuration(elapsedTime)
    }

    var formattedPace: String {
        currentPace
    }

    var formattedDistance: String {
        String(format: "%.2f", distanceKm)
    }

    var formattedElevation: String {
        String(format: "+%.0f m", elevationGainM)
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConfiguration.RunTracking.timerInterval))
                guard !Task.isCancelled else { break }
                self?.elapsedTime += AppConfiguration.RunTracking.timerInterval
            }
        }
    }

    // MARK: - Location

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
        let elevation = RunStatisticsCalculator.elevationChanges(trackPoints)
        elevationGainM = elevation.gainM
        elevationLossM = elevation.lossM

        if distanceKm > 0 {
            let pace = RunStatisticsCalculator.averagePace(
                distanceKm: distanceKm, duration: elapsedTime
            )
            currentPace = RunStatisticsCalculator.formatPace(pace)
        }

        handleAutoPause(speed: location.speed)
    }

    // MARK: - Heart Rate

    private func startHeartRateStreaming() {
        let stream = healthKitService.startHeartRateStream()
        heartRateTask = Task { [weak self] in
            for await reading in stream {
                guard !Task.isCancelled else { break }
                self?.currentHeartRate = reading.beatsPerMinute
            }
        }
    }

    // MARK: - Auto Pause

    private func handleAutoPause(speed: CLLocationSpeed) {
        guard runState == .running else { return }

        if speed < AppConfiguration.RunTracking.autoPauseSpeedThreshold && speed >= 0 {
            autoPauseTimer += AppConfiguration.RunTracking.timerInterval
            if autoPauseTimer >= AppConfiguration.RunTracking.autoPauseDelay {
                pauseRun()
                autoPauseTimer = 0
            }
        } else {
            autoPauseTimer = 0
        }
    }
}
