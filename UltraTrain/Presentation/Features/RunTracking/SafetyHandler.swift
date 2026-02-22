import Foundation
import os

@Observable
@MainActor
final class SafetyHandler {

    // MARK: - State

    var activeAlert: SafetyAlert?
    var countdownRemaining: Int = 0
    var isCountingDown: Bool = false
    var showMessageCompose: Bool = false
    var emergencyMessage: String = ""
    var emergencyPhoneNumbers: [String] = []

    var isActive: Bool { config.sosEnabled || config.fallDetectionEnabled || config.noMovementAlertEnabled }

    // MARK: - Dependencies

    private let emergencyContactRepository: any EmergencyContactRepository
    private let motionService: (any MotionServiceProtocol)?
    private let hapticService: any HapticServiceProtocol
    private let config: SafetyConfig

    // MARK: - Private

    private var lastMovementTime: Date = Date.now
    private var motionBuffer: [MotionReading] = []
    private var motionTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var contacts: [EmergencyContact] = []
    private var runStartTime: Date = Date.now

    // MARK: - Context

    struct RunContext: Sendable {
        let elapsedTime: TimeInterval
        let distanceKm: Double
        let latitude: Double?
        let longitude: Double?
        let isRunPaused: Bool
        let currentSpeed: Double
    }

    // MARK: - Init

    init(
        emergencyContactRepository: any EmergencyContactRepository,
        motionService: (any MotionServiceProtocol)?,
        hapticService: any HapticServiceProtocol,
        config: SafetyConfig
    ) {
        self.emergencyContactRepository = emergencyContactRepository
        self.motionService = motionService
        self.hapticService = hapticService
        self.config = config
    }

    // MARK: - Start / Stop

    func start() async {
        runStartTime = Date.now
        lastMovementTime = Date.now

        do {
            contacts = try await emergencyContactRepository.getContacts()
                .filter(\.isEnabled)
        } catch {
            Logger.safety.error("Failed to load emergency contacts: \(error)")
        }

        emergencyPhoneNumbers = contacts.map(\.phoneNumber)

        if config.fallDetectionEnabled, let motionService, motionService.isAvailable {
            startMotionMonitoring(motionService: motionService)
        }
    }

    func stop() {
        motionTask?.cancel()
        motionTask = nil
        countdownTask?.cancel()
        countdownTask = nil
        motionService?.stopAccelerometerUpdates()
    }

    // MARK: - Tick

    func tick(context: RunContext) {
        if context.currentSpeed > 0.3 {
            lastMovementTime = Date.now
        }

        if config.noMovementAlertEnabled && activeAlert == nil && !isCountingDown {
            checkNoMovement(context: context)
        }

        if config.safetyTimerEnabled && activeAlert == nil && !isCountingDown {
            checkSafetyTimer(context: context)
        }
    }

    // MARK: - Manual SOS

    func triggerSOS(context: RunContext) {
        hapticService.playSOSAlert()
        let alert = SafetyAlert(
            id: UUID(),
            type: .sos,
            triggeredAt: Date.now,
            latitude: context.latitude,
            longitude: context.longitude,
            message: BuildEmergencyMessageUseCase.build(
                alertType: .sos,
                latitude: context.latitude,
                longitude: context.longitude,
                distanceKm: context.distanceKm,
                elapsedTime: context.elapsedTime,
                includeLocation: config.includeLocationInMessage
            ),
            status: .triggered
        )
        startCountdown(alert: alert)
    }

    // MARK: - Cancel

    func cancelAlert() {
        countdownTask?.cancel()
        countdownTask = nil
        isCountingDown = false
        countdownRemaining = 0
        if var alert = activeAlert {
            alert.status = .cancelled
        }
        activeAlert = nil
        Logger.safety.info("Safety alert cancelled by user")
    }

    // MARK: - Private — No Movement

    private func checkNoMovement(context: RunContext) {
        let shouldAlert = NoMovementDetector.shouldAlert(
            lastMovementTime: lastMovementTime,
            currentTime: Date.now,
            thresholdMinutes: config.noMovementThresholdMinutes,
            isRunPaused: context.isRunPaused
        )

        guard shouldAlert else { return }

        let alert = SafetyAlert(
            id: UUID(),
            type: .noMovement,
            triggeredAt: Date.now,
            latitude: context.latitude,
            longitude: context.longitude,
            message: BuildEmergencyMessageUseCase.build(
                alertType: .noMovement,
                latitude: context.latitude,
                longitude: context.longitude,
                distanceKm: context.distanceKm,
                elapsedTime: context.elapsedTime,
                includeLocation: config.includeLocationInMessage
            ),
            status: .triggered
        )
        hapticService.playFallDetectedAlert()
        startCountdown(alert: alert)
    }

    // MARK: - Private — Safety Timer

    private func checkSafetyTimer(context: RunContext) {
        let threshold = TimeInterval(config.safetyTimerDurationMinutes * 60)
        guard context.elapsedTime >= threshold else { return }

        let alert = SafetyAlert(
            id: UUID(),
            type: .safetyTimerExpired,
            triggeredAt: Date.now,
            latitude: context.latitude,
            longitude: context.longitude,
            message: BuildEmergencyMessageUseCase.build(
                alertType: .safetyTimerExpired,
                latitude: context.latitude,
                longitude: context.longitude,
                distanceKm: context.distanceKm,
                elapsedTime: context.elapsedTime,
                includeLocation: config.includeLocationInMessage
            ),
            status: .triggered
        )
        hapticService.playFallDetectedAlert()
        startCountdown(alert: alert)
    }

    // MARK: - Private — Motion Monitoring

    private func startMotionMonitoring(motionService: any MotionServiceProtocol) {
        motionTask = Task { [weak self] in
            let stream = motionService.startAccelerometerUpdates()
            for await reading in stream {
                guard !Task.isCancelled else { break }
                await self?.processMotionReading(reading)
            }
        }
    }

    private func processMotionReading(_ reading: MotionReading) {
        motionBuffer.append(reading)
        if motionBuffer.count > AppConfiguration.Safety.motionBufferSize {
            motionBuffer.removeFirst()
        }

        guard motionBuffer.count >= 10, activeAlert == nil, !isCountingDown else { return }

        let result = FallDetectionAlgorithm.analyze(readings: motionBuffer)
        guard result.isFallDetected else { return }

        motionBuffer.removeAll()

        let alert = SafetyAlert(
            id: UUID(),
            type: .fallDetected,
            triggeredAt: Date.now,
            latitude: nil,
            longitude: nil,
            message: BuildEmergencyMessageUseCase.build(
                alertType: .fallDetected,
                latitude: nil,
                longitude: nil,
                distanceKm: 0,
                elapsedTime: Date.now.timeIntervalSince(runStartTime),
                includeLocation: config.includeLocationInMessage
            ),
            status: .triggered
        )
        hapticService.playFallDetectedAlert()
        startCountdown(alert: alert)
        Logger.safety.warning("Fall detected — impact: \(result.impactG)g")
    }

    // MARK: - Private — Countdown

    private func startCountdown(alert: SafetyAlert) {
        activeAlert = alert
        countdownRemaining = config.countdownBeforeSendingSeconds
        isCountingDown = true

        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while self.countdownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.countdownRemaining -= 1
            }
            guard !Task.isCancelled else { return }
            self.sendAlert()
        }
    }

    private func sendAlert() {
        guard let alert = activeAlert else { return }
        isCountingDown = false
        emergencyMessage = alert.message
        showMessageCompose = true

        var updatedAlert = alert
        updatedAlert.status = .sent
        activeAlert = updatedAlert

        Logger.safety.warning("Emergency alert sent: \(alert.type.rawValue)")
    }
}
