import Foundation
@testable import UltraTrain

final class MockExportService: ExportServiceProtocol, @unchecked Sendable {
    var exportRunAsGPXCalled = false
    var exportRunsAsCSVCalled = false
    var exportRunTrackAsCSVCalled = false
    var shouldThrow = false

    func exportRunAsGPX(_ run: CompletedRun) async throws -> URL {
        exportRunAsGPXCalled = true
        if shouldThrow { throw DomainError.exportFailed(reason: "Mock error") }
        return URL(fileURLWithPath: "/tmp/mock.gpx")
    }

    func exportRunsAsCSV(_ runs: [CompletedRun]) async throws -> URL {
        exportRunsAsCSVCalled = true
        if shouldThrow { throw DomainError.exportFailed(reason: "Mock error") }
        return URL(fileURLWithPath: "/tmp/mock.csv")
    }

    func exportRunTrackAsCSV(_ run: CompletedRun) async throws -> URL {
        exportRunTrackAsCSVCalled = true
        if shouldThrow { throw DomainError.exportFailed(reason: "Mock error") }
        return URL(fileURLWithPath: "/tmp/mock_track.csv")
    }
}
