import Foundation

protocol RecoveryRepository: Sendable {
    func getSnapshots(from startDate: Date, to endDate: Date) async throws -> [RecoverySnapshot]
    func getLatestSnapshot() async throws -> RecoverySnapshot?
    func saveSnapshot(_ snapshot: RecoverySnapshot) async throws
}
