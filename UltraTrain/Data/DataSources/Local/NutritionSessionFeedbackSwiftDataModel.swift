import Foundation
import SwiftData

@Model
final class NutritionSessionFeedbackSwiftDataModel {
    var id: UUID = UUID()
    var sessionId: UUID = UUID()
    var plannedCarbsPerHour: Int = 0
    var actualCarbsConsumed: Int = 0
    var durationMinutes: Int = 0
    var nausea: Int = 0
    var bloating: Int = 0
    var cramping: Int = 0
    var urgency: Int = 0
    var energyLevel: Int = 0
    var bonked: Bool = false
    var toleratedProductIdsData: Data = Data()
    var intolerantProductIdsData: Data = Data()
    var notes: String?
    var createdAt: Date = Date.distantPast

    init(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        plannedCarbsPerHour: Int = 0,
        actualCarbsConsumed: Int = 0,
        durationMinutes: Int = 0,
        nausea: Int = 0,
        bloating: Int = 0,
        cramping: Int = 0,
        urgency: Int = 0,
        energyLevel: Int = 0,
        bonked: Bool = false,
        toleratedProductIdsData: Data = Data(),
        intolerantProductIdsData: Data = Data(),
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.plannedCarbsPerHour = plannedCarbsPerHour
        self.actualCarbsConsumed = actualCarbsConsumed
        self.durationMinutes = durationMinutes
        self.nausea = nausea
        self.bloating = bloating
        self.cramping = cramping
        self.urgency = urgency
        self.energyLevel = energyLevel
        self.bonked = bonked
        self.toleratedProductIdsData = toleratedProductIdsData
        self.intolerantProductIdsData = intolerantProductIdsData
        self.notes = notes
        self.createdAt = createdAt
    }
}
