import Foundation

enum StravaUploadStatus: Sendable, Equatable {
    case idle
    case uploading
    case processing
    case success(activityId: Int)
    case failed(reason: String)
}

protocol StravaUploadServiceProtocol: Sendable {
    func uploadRun(_ run: CompletedRun) async throws -> Int
}
