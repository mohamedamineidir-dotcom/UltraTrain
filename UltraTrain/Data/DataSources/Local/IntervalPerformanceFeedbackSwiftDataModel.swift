import Foundation
import SwiftData

@Model
final class IntervalPerformanceFeedbackSwiftDataModel {
    var id: UUID = UUID()
    var sessionId: UUID = UUID()
    /// Raw value of `SessionType`. Stored as String for stable migration
    /// (SwiftData + enum default-value quirks).
    var sessionTypeRaw: String = SessionType.intervals.rawValue
    var targetPacePerKmAtTime: Double = 0
    var prescribedRepCount: Int = 0
    /// JSON-encoded [Double] of per-rep paces. Empty Data when the athlete
    /// used the "hit target consistently" shortcut.
    var actualPacesData: Data = Data()
    var completedAllReps: Bool = false
    var perceivedEffort: Int = 0
    var notes: String?
    var createdAt: Date = Date.distantPast

    init(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        sessionTypeRaw: String = SessionType.intervals.rawValue,
        targetPacePerKmAtTime: Double = 0,
        prescribedRepCount: Int = 0,
        actualPacesData: Data = Data(),
        completedAllReps: Bool = false,
        perceivedEffort: Int = 0,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.sessionTypeRaw = sessionTypeRaw
        self.targetPacePerKmAtTime = targetPacePerKmAtTime
        self.prescribedRepCount = prescribedRepCount
        self.actualPacesData = actualPacesData
        self.completedAllReps = completedAllReps
        self.perceivedEffort = perceivedEffort
        self.notes = notes
        self.createdAt = createdAt
    }
}
