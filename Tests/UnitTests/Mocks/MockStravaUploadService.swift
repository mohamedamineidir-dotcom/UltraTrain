import Foundation
@testable import UltraTrain

final class MockStravaUploadService: StravaUploadServiceProtocol, @unchecked Sendable {
    var shouldThrow = false
    var uploadedRun: CompletedRun?
    var returnedActivityId = 12345

    func uploadRun(_ run: CompletedRun) async throws -> Int {
        if shouldThrow {
            throw DomainError.stravaUploadFailed(reason: "Mock upload error")
        }
        uploadedRun = run
        return returnedActivityId
    }
}
