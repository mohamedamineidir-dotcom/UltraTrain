import Vapor

struct FriendRequestRequest: Content, Validatable {
    let recipientProfileId: String

    static func validations(_ validations: inout Validations) {
        validations.add("recipientProfileId", as: String.self, is: !.empty)
    }
}

struct FriendConnectionResponse: Content {
    let id: String
    let friendProfileId: String
    let friendDisplayName: String
    let status: String
    let createdDate: String
    let acceptedDate: String?

    init(from model: FriendConnectionModel, currentUserId: UUID, friendDisplayName: String) {
        let formatter = ISO8601DateFormatter()
        self.id = model.id?.uuidString ?? ""
        // The "friend" is whichever side is NOT the current user
        let friendId = model.$requestor.id == currentUserId ? model.$recipient.id : model.$requestor.id
        self.friendProfileId = friendId.uuidString
        self.friendDisplayName = friendDisplayName
        self.status = model.status
        self.createdDate = model.createdAt.map { formatter.string(from: $0) } ?? ""
        self.acceptedDate = model.acceptedAt.map { formatter.string(from: $0) }
    }
}
