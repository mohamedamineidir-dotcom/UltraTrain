import Foundation

struct SleepEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var totalSleepDuration: TimeInterval
    var deepSleepDuration: TimeInterval
    var remSleepDuration: TimeInterval
    var coreSleepDuration: TimeInterval
    var sleepEfficiency: Double
    var bedtime: Date
    var wakeTime: Date
    var timeInBed: TimeInterval
}
