import Foundation

struct WeeklyAdherence: Identifiable, Equatable {
    let id: Date
    var weekStartDate: Date
    var weekNumber: Int
    var completed: Int
    var total: Int
    var percent: Double

    init(weekStartDate: Date, weekNumber: Int, completed: Int, total: Int) {
        self.id = weekStartDate
        self.weekStartDate = weekStartDate
        self.weekNumber = weekNumber
        self.completed = completed
        self.total = total
        self.percent = total > 0 ? Double(completed) / Double(total) * 100 : 0
    }
}
