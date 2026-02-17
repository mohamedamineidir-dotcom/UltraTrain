import Foundation

protocol StravaImportServiceProtocol: Sendable {
    func fetchActivities(page: Int, perPage: Int) async throws -> [StravaActivity]
    func importActivity(_ activity: StravaActivity, athleteId: UUID) async throws -> CompletedRun
}
