import Foundation
import SwiftData

@Model
final class ChallengeEnrollmentSwiftDataModel {
    var id: UUID = UUID()
    var challengeDefinitionId: String = ""
    var startDate: Date = Date()
    var statusRaw: String = "active"
    var completedDate: Date? = nil
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        challengeDefinitionId: String = "",
        startDate: Date = Date(),
        statusRaw: String = "active",
        completedDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.challengeDefinitionId = challengeDefinitionId
        self.startDate = startDate
        self.statusRaw = statusRaw
        self.completedDate = completedDate
        self.updatedAt = updatedAt
    }
}
