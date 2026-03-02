import Foundation

struct CrashReport: Codable, Sendable, Identifiable {
    let id: UUID
    let timestamp: Date
    let errorType: String
    let errorMessage: String
    let stackTrace: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let buildNumber: String
    let context: [String: String]
}
