import Foundation

struct ACRDataPoint: Identifiable, Equatable, Sendable {
    let id: Date
    var date: Date
    var value: Double

    init(date: Date, value: Double) {
        self.id = date
        self.date = date
        self.value = value
    }
}
