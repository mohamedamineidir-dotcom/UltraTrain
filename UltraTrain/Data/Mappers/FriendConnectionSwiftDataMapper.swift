import Foundation

enum FriendConnectionSwiftDataMapper {

    static func toDomain(_ model: FriendConnectionSwiftDataModel) -> FriendConnection? {
        guard let status = FriendStatus(rawValue: model.statusRaw) else {
            return nil
        }
        return FriendConnection(
            id: model.id,
            friendProfileId: model.friendProfileId,
            friendDisplayName: model.friendDisplayName,
            friendPhotoData: model.friendPhotoData,
            status: status,
            createdDate: model.createdDate,
            acceptedDate: model.acceptedDate
        )
    }

    static func toSwiftData(_ connection: FriendConnection) -> FriendConnectionSwiftDataModel {
        FriendConnectionSwiftDataModel(
            id: connection.id,
            friendProfileId: connection.friendProfileId,
            friendDisplayName: connection.friendDisplayName,
            friendPhotoData: connection.friendPhotoData,
            statusRaw: connection.status.rawValue,
            createdDate: connection.createdDate,
            acceptedDate: connection.acceptedDate
        )
    }
}
