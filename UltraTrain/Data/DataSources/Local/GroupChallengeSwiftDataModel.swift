import Foundation
import SwiftData

@Model
final class GroupChallengeSwiftDataModel {
    var id: UUID = UUID()
    var creatorProfileId: String = ""
    var creatorDisplayName: String = ""
    var name: String = ""
    var descriptionText: String = ""
    var typeRaw: String = "distance"
    var targetValue: Double = 0
    var startDate: Date = Date()
    var endDate: Date = Date()
    var statusRaw: String = "active"
    @Attribute(.externalStorage) var participantsData: Data = Data()

    init(
        id: UUID = UUID(),
        creatorProfileId: String = "",
        creatorDisplayName: String = "",
        name: String = "",
        descriptionText: String = "",
        typeRaw: String = "distance",
        targetValue: Double = 0,
        startDate: Date = Date(),
        endDate: Date = Date(),
        statusRaw: String = "active",
        participantsData: Data = Data()
    ) {
        self.id = id
        self.creatorProfileId = creatorProfileId
        self.creatorDisplayName = creatorDisplayName
        self.name = name
        self.descriptionText = descriptionText
        self.typeRaw = typeRaw
        self.targetValue = targetValue
        self.startDate = startDate
        self.endDate = endDate
        self.statusRaw = statusRaw
        self.participantsData = participantsData
    }
}
