import Testing
@testable import UltraTrain

struct PrivacyTrackingServiceTests {

    @Test func mockDefaultStatusIsNotDetermined() {
        let service = MockPrivacyTrackingService()
        #expect(service.authorizationStatus == .notDetermined)
    }

    @Test func mockRequestReturnsConfiguredStatus() async {
        let service = MockPrivacyTrackingService()
        service.stubbedRequestResult = .authorized
        let result = await service.requestAuthorization()
        #expect(result == .authorized)
        #expect(service.requestCount == 1)
    }

    @Test func mockRequestDenied() async {
        let service = MockPrivacyTrackingService()
        service.stubbedRequestResult = .denied
        let result = await service.requestAuthorization()
        #expect(result == .denied)
        #expect(service.authorizationStatus == .denied)
    }

    @Test func mockRequestRestricted() async {
        let service = MockPrivacyTrackingService()
        service.stubbedRequestResult = .restricted
        let result = await service.requestAuthorization()
        #expect(result == .restricted)
    }

    @Test func trackingAuthorizationStatusDisplayDescription() {
        #expect(TrackingAuthorizationStatus.notDetermined.displayDescription == "Not Requested")
        #expect(TrackingAuthorizationStatus.restricted.displayDescription == "Restricted")
        #expect(TrackingAuthorizationStatus.denied.displayDescription == "Denied")
        #expect(TrackingAuthorizationStatus.authorized.displayDescription == "Authorized")
    }
}
