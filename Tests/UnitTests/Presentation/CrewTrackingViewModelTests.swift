import Foundation
import Testing
@testable import UltraTrain

@Suite("CrewTrackingViewModel Tests")
struct CrewTrackingViewModelTests {

    // MARK: - Helpers

    private func makeSession(id: UUID = UUID()) -> CrewTrackingSession {
        CrewTrackingSession(
            id: id,
            hostProfileId: "host-1",
            hostDisplayName: "Host Runner",
            startedAt: Date.now,
            status: .active,
            participants: [
                CrewParticipant(
                    id: "p1",
                    displayName: "Runner 1",
                    latitude: 48.8566,
                    longitude: 2.3522,
                    distanceKm: 5.0,
                    currentPaceSecondsPerKm: 300,
                    lastUpdated: Date.now
                )
            ]
        )
    }

    @MainActor
    private func makeSUT(
        crewService: MockCrewTrackingService = MockCrewTrackingService(),
        profileRepo: MockSocialProfileRepository = MockSocialProfileRepository()
    ) -> (CrewTrackingViewModel, MockCrewTrackingService) {
        let vm = CrewTrackingViewModel(
            crewService: crewService,
            profileRepository: profileRepo
        )
        return (vm, crewService)
    }

    // MARK: - Tests

    @Test("startSession creates session and sets isHost")
    @MainActor
    func startSessionCreatesAndSetsHost() async {
        let service = MockCrewTrackingService()
        let expectedSession = makeSession()
        service.sessionToReturn = expectedSession
        let (vm, _) = makeSUT(crewService: service)

        await vm.startSession()

        #expect(vm.session != nil)
        #expect(vm.session?.id == expectedSession.id)
        #expect(vm.isHost == true)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("startSession sets error on failure")
    @MainActor
    func startSessionError() async {
        let service = MockCrewTrackingService()
        service.shouldThrow = true
        let (vm, _) = makeSUT(crewService: service)

        await vm.startSession()

        #expect(vm.session == nil)
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("joinSession fetches session and sets isHost to false")
    @MainActor
    func joinSessionFetchesAndNotHost() async {
        let service = MockCrewTrackingService()
        let sessionId = UUID()
        let session = makeSession(id: sessionId)
        service.sessionToReturn = session
        let (vm, _) = makeSUT(crewService: service)

        await vm.joinSession(id: sessionId)

        #expect(vm.session?.id == sessionId)
        #expect(vm.isHost == false)
        #expect(vm.isLoading == false)
        #expect(service.joinedSessionId == sessionId)
    }

    @Test("joinSession sets error on failure")
    @MainActor
    func joinSessionError() async {
        let service = MockCrewTrackingService()
        service.shouldThrow = true
        let (vm, _) = makeSUT(crewService: service)

        await vm.joinSession(id: UUID())

        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("updateMyLocation does nothing without active session")
    @MainActor
    func updateLocationNoSession() async {
        let (vm, service) = makeSUT()

        await vm.updateMyLocation(latitude: 48.0, longitude: 2.0, distanceKm: 5, paceSecondsPerKm: 300)

        #expect(service.updatedLocation == nil)
    }

    @Test("updateMyLocation sends data with active session")
    @MainActor
    func updateLocationWithSession() async {
        let service = MockCrewTrackingService()
        let session = makeSession()
        service.sessionToReturn = session
        let (vm, _) = makeSUT(crewService: service)
        await vm.startSession()

        await vm.updateMyLocation(latitude: 48.0, longitude: 2.0, distanceKm: 10, paceSecondsPerKm: 330)

        #expect(service.updatedLocation?.sessionId == session.id)
        #expect(service.updatedLocation?.lat == 48.0)
        #expect(service.updatedLocation?.dist == 10)
    }

    @Test("endSession clears session and isHost")
    @MainActor
    func endSessionClearsState() async {
        let service = MockCrewTrackingService()
        let session = makeSession()
        service.sessionToReturn = session
        let (vm, _) = makeSUT(crewService: service)
        await vm.startSession()

        #expect(vm.session != nil)

        await vm.endSession()

        #expect(vm.session == nil)
        #expect(vm.isHost == false)
        #expect(service.endedSessionId == session.id)
    }

    @Test("leaveSession clears session and isHost")
    @MainActor
    func leaveSessionClearsState() async {
        let service = MockCrewTrackingService()
        let sessionId = UUID()
        let session = makeSession(id: sessionId)
        service.sessionToReturn = session
        let (vm, _) = makeSUT(crewService: service)
        await vm.joinSession(id: sessionId)

        await vm.leaveSession()

        #expect(vm.session == nil)
        #expect(vm.isHost == false)
        #expect(service.leftSessionId == sessionId)
    }

    @Test("refreshSession updates session data")
    @MainActor
    func refreshSessionUpdatesData() async {
        let service = MockCrewTrackingService()
        let sessionId = UUID()
        let initialSession = makeSession(id: sessionId)
        service.sessionToReturn = initialSession
        let (vm, _) = makeSUT(crewService: service)
        await vm.startSession()

        // Update the session to return with more participants
        let updatedSession = CrewTrackingSession(
            id: sessionId,
            hostProfileId: "host-1",
            hostDisplayName: "Host Runner",
            startedAt: Date.now,
            status: .active,
            participants: [
                CrewParticipant(id: "p1", displayName: "Runner 1", latitude: 48.0, longitude: 2.0, distanceKm: 10, currentPaceSecondsPerKm: 300, lastUpdated: Date.now),
                CrewParticipant(id: "p2", displayName: "Runner 2", latitude: 48.1, longitude: 2.1, distanceKm: 8, currentPaceSecondsPerKm: 330, lastUpdated: Date.now)
            ]
        )
        service.sessionToReturn = updatedSession

        await vm.refreshSession()

        #expect(vm.session?.participants.count == 2)
    }
}
