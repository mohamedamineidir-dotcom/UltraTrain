import Foundation

enum IntervalPerformanceFeedbackMapper {

    static func toDomain(_ model: IntervalPerformanceFeedbackSwiftDataModel) -> IntervalPerformanceFeedback {
        IntervalPerformanceFeedback(
            id: model.id,
            sessionId: model.sessionId,
            sessionType: SessionType(rawValue: model.sessionTypeRaw) ?? .intervals,
            targetPacePerKmAtTime: model.targetPacePerKmAtTime,
            prescribedRepCount: model.prescribedRepCount,
            actualPacesPerKm: decodePaces(from: model.actualPacesData),
            completedAllReps: model.completedAllReps,
            perceivedEffort: model.perceivedEffort,
            notes: model.notes,
            createdAt: model.createdAt
        )
    }

    static func toSwiftData(_ feedback: IntervalPerformanceFeedback) -> IntervalPerformanceFeedbackSwiftDataModel {
        IntervalPerformanceFeedbackSwiftDataModel(
            id: feedback.id,
            sessionId: feedback.sessionId,
            sessionTypeRaw: feedback.sessionType.rawValue,
            targetPacePerKmAtTime: feedback.targetPacePerKmAtTime,
            prescribedRepCount: feedback.prescribedRepCount,
            actualPacesData: encodePaces(feedback.actualPacesPerKm),
            completedAllReps: feedback.completedAllReps,
            perceivedEffort: feedback.perceivedEffort,
            notes: feedback.notes,
            createdAt: feedback.createdAt
        )
    }

    private static func encodePaces(_ paces: [Double]) -> Data {
        (try? JSONEncoder().encode(paces)) ?? Data()
    }

    private static func decodePaces(from data: Data) -> [Double] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([Double].self, from: data)) ?? []
    }
}
