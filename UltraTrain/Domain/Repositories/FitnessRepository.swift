import Foundation

protocol FitnessRepository: Sendable {
    func getSnapshots(from: Date, to: Date) async throws -> [FitnessSnapshot]
    func getLatestSnapshot() async throws -> FitnessSnapshot?
    func saveSnapshot(_ snapshot: FitnessSnapshot) async throws
}
