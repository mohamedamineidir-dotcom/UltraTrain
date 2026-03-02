import Foundation
import Testing
@testable import UltraTrain

@Suite("StravaUploadService Tests")
struct StravaUploadServiceTests {

    // MARK: - Helpers

    private func makeCompletedRun(
        gpsTrack: [TrackPoint] = [
            TrackPoint(latitude: 45.83, longitude: 6.86, altitudeM: 1500, timestamp: Date(), heartRate: 140),
            TrackPoint(latitude: 45.84, longitude: 6.87, altitudeM: 1550, timestamp: Date().addingTimeInterval(60), heartRate: 145)
        ],
        distanceKm: Double = 10.0
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date(),
            distanceKm: distanceKm,
            elevationGainM: 300,
            elevationLossM: 280,
            duration: 3600,
            averageHeartRate: 148,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: gpsTrack,
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    // MARK: - Upload Validation

    @Test("uploadRun throws when GPS track is empty")
    func uploadThrowsForEmptyGPS() async {
        let authService = MockStravaAuthService()
        authService.connected = true
        let service = StravaUploadService(authService: authService)
        let run = makeCompletedRun(gpsTrack: [])

        do {
            _ = try await service.uploadRun(run)
            Issue.record("Expected DomainError.stravaUploadFailed")
        } catch {
            if let domainError = error as? DomainError,
               case .stravaUploadFailed(let reason) = domainError {
                #expect(reason.contains("no GPS data"))
            } else {
                Issue.record("Expected DomainError.stravaUploadFailed, got \(error)")
            }
        }
    }

    @Test("uploadRun throws when not authenticated")
    func uploadThrowsWhenNotAuthenticated() async {
        let authService = MockStravaAuthService()
        authService.connected = false
        let service = StravaUploadService(authService: authService)
        let run = makeCompletedRun()

        do {
            _ = try await service.uploadRun(run)
            Issue.record("Expected error for unauthenticated upload")
        } catch {
            // Should throw stravaAuthFailed since getValidToken throws when not connected
            #expect(error is DomainError)
        }
    }

    @Test("uploadRun throws when auth service fails")
    func uploadThrowsWhenAuthFails() async {
        let authService = MockStravaAuthService()
        authService.shouldThrow = true
        let service = StravaUploadService(authService: authService)
        let run = makeCompletedRun()

        do {
            _ = try await service.uploadRun(run)
            Issue.record("Expected DomainError.stravaAuthFailed")
        } catch {
            #expect(error is DomainError)
        }
    }

    // MARK: - Mock Protocol

    @Test("MockStravaUploadService returns configured activity ID")
    func mockReturnsConfiguredActivityId() async throws {
        let mock = MockStravaUploadService()
        mock.returnedActivityId = 99999
        let run = makeCompletedRun()

        let activityId = try await mock.uploadRun(run)
        #expect(activityId == 99999)
        #expect(mock.uploadedRun != nil)
    }

    @Test("MockStravaUploadService throws when configured to fail")
    func mockThrowsWhenConfigured() async {
        let mock = MockStravaUploadService()
        mock.shouldThrow = true
        let run = makeCompletedRun()

        do {
            _ = try await mock.uploadRun(run)
            Issue.record("Expected error from mock")
        } catch {
            #expect(error is DomainError)
        }
    }

    // MARK: - StravaUploadStatus

    @Test("StravaUploadStatus idle is equatable")
    func uploadStatusEquatable() {
        #expect(StravaUploadStatus.idle == StravaUploadStatus.idle)
        #expect(StravaUploadStatus.uploading == StravaUploadStatus.uploading)
        #expect(StravaUploadStatus.processing == StravaUploadStatus.processing)
        #expect(StravaUploadStatus.success(activityId: 123) == StravaUploadStatus.success(activityId: 123))
        #expect(StravaUploadStatus.success(activityId: 123) != StravaUploadStatus.success(activityId: 456))
        #expect(StravaUploadStatus.failed(reason: "test") == StravaUploadStatus.failed(reason: "test"))
    }
}
