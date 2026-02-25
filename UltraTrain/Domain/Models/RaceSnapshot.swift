import Foundation

struct RaceSnapshot: Codable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let priority: RacePriority
}
