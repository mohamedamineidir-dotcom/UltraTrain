import Foundation

struct TrainingLoadSummary: Equatable, Sendable {
    var currentWeekLoad: WeeklyLoadData
    var weeklyHistory: [WeeklyLoadData]
    var acrTrend: [ACRDataPoint]
    var monotony: Double
    var monotonyLevel: MonotonyLevel
}
