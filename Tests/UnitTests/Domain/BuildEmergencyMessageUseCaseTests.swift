import Foundation
import Testing
@testable import UltraTrain

@Suite("BuildEmergencyMessageUseCase Tests")
struct BuildEmergencyMessageUseCaseTests {

    // MARK: - Alert Type Text

    @Test("Message includes SOS alert type text")
    func messageIncludesSOSAlertType() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .sos,
            latitude: nil,
            longitude: nil,
            distanceKm: 5.0,
            elapsedTime: 1800,
            includeLocation: false
        )

        #expect(message.contains("SOS"))
        #expect(message.contains("manually triggered an SOS"))
    }

    @Test("Message includes Fall Detected alert type text")
    func messageIncludesFallDetectedAlertType() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .fallDetected,
            latitude: nil,
            longitude: nil,
            distanceKm: 3.0,
            elapsedTime: 900,
            includeLocation: false
        )

        #expect(message.contains("Fall Detected"))
        #expect(message.contains("possible fall/crash"))
    }

    // MARK: - Location

    @Test("Message includes location link when coordinates provided and includeLocation is true")
    func messageIncludesLocationLink() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .sos,
            latitude: 45.8326,
            longitude: 6.8652,
            distanceKm: 10.0,
            elapsedTime: 3600,
            includeLocation: true
        )

        #expect(message.contains("Last known location:"))
        #expect(message.contains("maps.apple.com"))
        #expect(message.contains("45.8326"))
        #expect(message.contains("6.8652"))
    }

    @Test("Message excludes location when includeLocation is false")
    func messageExcludesLocationWhenDisabled() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .sos,
            latitude: 45.8326,
            longitude: 6.8652,
            distanceKm: 10.0,
            elapsedTime: 3600,
            includeLocation: false
        )

        #expect(!message.contains("Last known location:"))
        #expect(!message.contains("maps.apple.com"))
    }

    @Test("Message excludes location when coordinates are nil")
    func messageExcludesLocationWhenNilCoordinates() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .sos,
            latitude: nil,
            longitude: nil,
            distanceKm: 5.0,
            elapsedTime: 1800,
            includeLocation: true
        )

        #expect(!message.contains("Last known location:"))
        #expect(!message.contains("maps.apple.com"))
    }

    // MARK: - Run Duration and Distance

    @Test("Message includes run duration and distance")
    func messageIncludesRunStats() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .noMovement,
            latitude: nil,
            longitude: nil,
            distanceKm: 12.5,
            elapsedTime: 5400, // 90 minutes
            includeLocation: false
        )

        #expect(message.contains("12.5 km"))
        #expect(message.contains("90 min"))
    }

    // MARK: - All Alert Types

    @Test("All alert types produce valid non-empty messages",
          arguments: [SafetyAlertType.sos, .fallDetected, .noMovement, .safetyTimerExpired])
    func allAlertTypesProduceValidMessages(alertType: SafetyAlertType) {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: alertType,
            latitude: 48.8566,
            longitude: 2.3522,
            distanceKm: 8.0,
            elapsedTime: 2700,
            includeLocation: true
        )

        #expect(!message.isEmpty)
        #expect(message.contains("EMERGENCY ALERT"))
        #expect(message.contains(alertType.displayName))
        #expect(message.contains("UltraTrain"))
    }

    @Test("No movement alert type includes correct description")
    func noMovementDescription() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .noMovement,
            latitude: nil,
            longitude: nil,
            distanceKm: 2.0,
            elapsedTime: 600,
            includeLocation: false
        )

        #expect(message.contains("No movement has been detected"))
    }

    @Test("Safety timer expired alert type includes correct description")
    func safetyTimerExpiredDescription() {
        let message = BuildEmergencyMessageUseCase.build(
            alertType: .safetyTimerExpired,
            latitude: nil,
            longitude: nil,
            distanceKm: 20.0,
            elapsedTime: 7200,
            includeLocation: false
        )

        #expect(message.contains("safety check-in timer has expired"))
    }
}
