import Foundation

enum FriendStatus: String, Sendable, CaseIterable {
    case pending
    case accepted
    case declined
}

struct FriendConnection: Identifiable, Equatable, Sendable {
    let id: UUID
    var friendProfileId: String
    var friendDisplayName: String
    var friendPhotoData: Data?
    var status: FriendStatus
    var createdDate: Date
    var acceptedDate: Date?
}
