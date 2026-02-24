@testable import UltraTrain

final class MockPrivacyTrackingService: PrivacyTrackingServiceProtocol, @unchecked Sendable {
    var stubbedStatus: TrackingAuthorizationStatus = .notDetermined
    var requestCount = 0
    var stubbedRequestResult: TrackingAuthorizationStatus = .authorized

    var authorizationStatus: TrackingAuthorizationStatus {
        stubbedStatus
    }

    func requestAuthorization() async -> TrackingAuthorizationStatus {
        requestCount += 1
        stubbedStatus = stubbedRequestResult
        return stubbedRequestResult
    }
}
