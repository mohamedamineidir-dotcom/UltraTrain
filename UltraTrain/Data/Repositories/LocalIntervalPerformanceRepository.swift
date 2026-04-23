import Foundation
import SwiftData
import os

// @unchecked Sendable: thread-safe via ModelContainer (new context per call).
final class LocalIntervalPerformanceRepository: IntervalPerformanceRepository, @unchecked Sendable {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func save(_ feedback: IntervalPerformanceFeedback) async throws {
        let context = ModelContext(modelContainer)
        let targetSessionId = feedback.sessionId
        let existing = FetchDescriptor<IntervalPerformanceFeedbackSwiftDataModel>(
            predicate: #Predicate { $0.sessionId == targetSessionId }
        )
        for old in try context.fetch(existing) {
            context.delete(old)
        }
        let model = IntervalPerformanceFeedbackMapper.toSwiftData(feedback)
        context.insert(model)
        try context.save()
        Logger.training.info("Interval performance feedback saved for session \(feedback.sessionId)")
    }

    func getAll() async throws -> [IntervalPerformanceFeedback] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<IntervalPerformanceFeedbackSwiftDataModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(IntervalPerformanceFeedbackMapper.toDomain)
    }

    func get(for sessionId: UUID) async throws -> IntervalPerformanceFeedback? {
        let context = ModelContext(modelContainer)
        let targetSessionId = sessionId
        var descriptor = FetchDescriptor<IntervalPerformanceFeedbackSwiftDataModel>(
            predicate: #Predicate { $0.sessionId == targetSessionId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(IntervalPerformanceFeedbackMapper.toDomain)
    }

    func getRecent(
        since cutoff: Date,
        sessionType: SessionType
    ) async throws -> [IntervalPerformanceFeedback] {
        let context = ModelContext(modelContainer)
        let targetType = sessionType.rawValue
        let descriptor = FetchDescriptor<IntervalPerformanceFeedbackSwiftDataModel>(
            predicate: #Predicate { $0.createdAt >= cutoff && $0.sessionTypeRaw == targetType },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(IntervalPerformanceFeedbackMapper.toDomain)
    }
}
