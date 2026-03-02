import Foundation
@testable import UltraTrain

final class MockCrashReporter: CrashReporterProtocol, @unchecked Sendable {
    private(set) var startCallCount = 0
    private(set) var reportedErrors: [(error: Error, context: [String: String])] = []
    private(set) var uploadCallCount = 0

    func start() {
        startCallCount += 1
    }

    func reportError(_ error: Error, context: [String: String]) {
        reportedErrors.append((error: error, context: context))
    }

    func uploadPendingReports() async {
        uploadCallCount += 1
    }
}
