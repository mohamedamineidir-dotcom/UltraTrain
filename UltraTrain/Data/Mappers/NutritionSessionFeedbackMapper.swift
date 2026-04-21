import Foundation

enum NutritionSessionFeedbackMapper {

    static func toDomain(_ model: NutritionSessionFeedbackSwiftDataModel) -> NutritionSessionFeedback {
        NutritionSessionFeedback(
            id: model.id,
            sessionId: model.sessionId,
            plannedCarbsPerHour: model.plannedCarbsPerHour,
            actualCarbsConsumed: model.actualCarbsConsumed,
            durationMinutes: model.durationMinutes,
            nausea: model.nausea,
            bloating: model.bloating,
            cramping: model.cramping,
            urgency: model.urgency,
            energyLevel: model.energyLevel,
            bonked: model.bonked,
            toleratedProductIds: decodeUUIDSet(from: model.toleratedProductIdsData),
            intolerantProductIds: decodeUUIDSet(from: model.intolerantProductIdsData),
            notes: model.notes,
            createdAt: model.createdAt
        )
    }

    static func toSwiftData(_ feedback: NutritionSessionFeedback) -> NutritionSessionFeedbackSwiftDataModel {
        NutritionSessionFeedbackSwiftDataModel(
            id: feedback.id,
            sessionId: feedback.sessionId,
            plannedCarbsPerHour: feedback.plannedCarbsPerHour,
            actualCarbsConsumed: feedback.actualCarbsConsumed,
            durationMinutes: feedback.durationMinutes,
            nausea: feedback.nausea,
            bloating: feedback.bloating,
            cramping: feedback.cramping,
            urgency: feedback.urgency,
            energyLevel: feedback.energyLevel,
            bonked: feedback.bonked,
            toleratedProductIdsData: encodeUUIDSet(feedback.toleratedProductIds),
            intolerantProductIdsData: encodeUUIDSet(feedback.intolerantProductIds),
            notes: feedback.notes,
            createdAt: feedback.createdAt
        )
    }

    private static func encodeUUIDSet(_ ids: Set<UUID>) -> Data {
        let strings = ids.map(\.uuidString)
        return (try? JSONEncoder().encode(strings)) ?? Data()
    }

    private static func decodeUUIDSet(from data: Data) -> Set<UUID> {
        guard let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
