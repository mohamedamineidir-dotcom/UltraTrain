import Vapor

struct CrashReportDTO: Content {
    let id: UUID
    let timestamp: Date
    let errorType: String
    let errorMessage: String
    let stackTrace: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let buildNumber: String
    let context: [String: String]?
}

extension CrashReportDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("errorType", as: String.self, is: !.empty)
        validations.add("errorMessage", as: String.self, is: !.empty)
        validations.add("deviceModel", as: String.self, is: !.empty)
        validations.add("osVersion", as: String.self, is: !.empty)
        validations.add("appVersion", as: String.self, is: !.empty)
        validations.add("buildNumber", as: String.self, is: !.empty)
    }
}
