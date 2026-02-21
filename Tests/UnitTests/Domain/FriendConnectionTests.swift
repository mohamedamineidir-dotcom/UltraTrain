import Foundation
import Testing
@testable import UltraTrain

@Suite("FriendConnection Model Tests")
struct FriendConnectionTests {

    private func makeConnection(
        status: FriendStatus = .pending,
        acceptedDate: Date? = nil
    ) -> FriendConnection {
        FriendConnection(
            id: UUID(),
            friendProfileId: "friend-456",
            friendDisplayName: "Mountain Goat",
            friendPhotoData: nil,
            status: status,
            createdDate: Date.now,
            acceptedDate: acceptedDate
        )
    }

    @Test("FriendConnection creation with all fields")
    func creationWithAllFields() {
        let conn = makeConnection(status: .accepted, acceptedDate: Date.now)

        #expect(conn.friendProfileId == "friend-456")
        #expect(conn.friendDisplayName == "Mountain Goat")
        #expect(conn.friendPhotoData == nil)
        #expect(conn.status == .accepted)
        #expect(conn.acceptedDate != nil)
    }

    @Test("FriendStatus pending case")
    func pendingStatus() {
        let conn = makeConnection(status: .pending)
        #expect(conn.status == .pending)
    }

    @Test("FriendStatus accepted case")
    func acceptedStatus() {
        let conn = makeConnection(status: .accepted)
        #expect(conn.status == .accepted)
    }

    @Test("FriendStatus declined case")
    func declinedStatus() {
        let conn = makeConnection(status: .declined)
        #expect(conn.status == .declined)
    }

    @Test("FriendStatus has all expected cases")
    func allCases() {
        let allCases = FriendStatus.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.pending))
        #expect(allCases.contains(.accepted))
        #expect(allCases.contains(.declined))
    }
}
