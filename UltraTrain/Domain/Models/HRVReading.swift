import Foundation

struct HRVReading: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let date: Date
    let sdnnMs: Double
    let source: String?

    init(id: UUID = UUID(), date: Date, sdnnMs: Double, source: String? = nil) {
        self.id = id
        self.date = date
        self.sdnnMs = sdnnMs
        self.source = source
    }
}
