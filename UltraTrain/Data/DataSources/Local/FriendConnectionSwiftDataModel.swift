import Foundation
import SwiftData

@Model
final class FriendConnectionSwiftDataModel {
    var id: UUID = UUID()
    var friendProfileId: String = ""
    var friendDisplayName: String = ""
    @Attribute(.externalStorage) var friendPhotoData: Data?
    var statusRaw: String = "pending"
    var createdDate: Date = Date()
    var acceptedDate: Date?

    init(
        id: UUID = UUID(),
        friendProfileId: String = "",
        friendDisplayName: String = "",
        friendPhotoData: Data? = nil,
        statusRaw: String = "pending",
        createdDate: Date = Date(),
        acceptedDate: Date? = nil
    ) {
        self.id = id
        self.friendProfileId = friendProfileId
        self.friendDisplayName = friendDisplayName
        self.friendPhotoData = friendPhotoData
        self.statusRaw = statusRaw
        self.createdDate = createdDate
        self.acceptedDate = acceptedDate
    }
}
