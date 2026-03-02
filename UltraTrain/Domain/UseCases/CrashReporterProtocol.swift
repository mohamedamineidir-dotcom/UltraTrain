import Foundation

protocol CrashReporterProtocol: Sendable {
    func start()
    func reportError(_ error: Error, context: [String: String])
    func uploadPendingReports() async
}
