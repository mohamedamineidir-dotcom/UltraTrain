import Foundation

struct FriendRequestRequestDTO: Encodable, Sendable {
    let recipientProfileId: String
}

struct FriendConnectionResponseDTO: Decodable, Sendable {
    let id: String
    let friendProfileId: String
    let friendDisplayName: String
    let status: String
    let createdDate: String
    let acceptedDate: String?
}
