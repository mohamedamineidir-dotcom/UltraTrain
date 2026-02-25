import Foundation

struct SplitPR: Identifiable, Equatable, Sendable {
    let id: UUID
    var kilometerNumber: Int
    var currentPace: Double
    var previousBestPace: Double
}
