import Foundation

struct FriendConnection: Identifiable, Equatable, Sendable {
    let id: UUID
    var friendProfileId: String
    var friendDisplayName: String
    var friendPhotoData: Data?
    var status: FriendStatus
    var createdDate: Date
    var acceptedDate: Date?
}
