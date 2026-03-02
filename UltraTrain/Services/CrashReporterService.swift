import Foundation
import os

final class CrashReporterService: CrashReporterProtocol, @unchecked Sendable {
    // NSLock required: persistReport is called from signal/exception handlers
    // which run in a constrained context incompatible with actors
    private let lock = NSLock()
    private let storageDirectory: URL
    private let apiClient: APIClient
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.storageDirectory = docs.appendingPathComponent("CrashReports", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func start() {
        installExceptionHandler()
        installSignalHandlers()
        Logger.crashReporter.info("Crash reporter started")
    }

    func reportError(_ error: Error, context: [String: String]) {
        let report = CrashReport(
            id: UUID(),
            timestamp: Date(),
            errorType: "caught",
            errorMessage: String(describing: error),
            stackTrace: Thread.callStackSymbols.joined(separator: "\n"),
            deviceModel: Self.deviceModel(),
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            appVersion: AppConfiguration.appVersion,
            buildNumber: AppConfiguration.buildNumber,
            context: context
        )
        persistReport(report)
        Logger.crashReporter.info("Error report saved: \(report.id)")
    }

    func uploadPendingReports() async {
        let reports = loadPendingReports()
        guard !reports.isEmpty else { return }
        Logger.crashReporter.info("Uploading \(reports.count) pending crash reports")

        for report in reports {
            do {
                try await apiClient.sendVoid(CrashEndpoints.Upload(body: report))
                deleteReport(id: report.id)
                Logger.crashReporter.info("Uploaded crash report \(report.id)")
            } catch {
                Logger.crashReporter.warning("Failed to upload crash report \(report.id): \(error)")
                break
            }
        }
    }

    // MARK: - Exception Handler

    private func installExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let report = CrashReport(
                id: UUID(),
                timestamp: Date(),
                errorType: "exception",
                errorMessage: "\(exception.name.rawValue): \(exception.reason ?? "unknown")",
                stackTrace: exception.callStackSymbols.joined(separator: "\n"),
                deviceModel: CrashReporterService.deviceModel(),
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                appVersion: AppConfiguration.appVersion,
                buildNumber: AppConfiguration.buildNumber,
                context: ["exceptionName": exception.name.rawValue]
            )
            CrashReporterService.persistReportSync(report)
        }
    }

    // MARK: - Signal Handlers

    private func installSignalHandlers() {
        let signals: [Int32] = [SIGABRT, SIGSEGV, SIGBUS, SIGFPE, SIGILL, SIGTRAP]
        for sig in signals {
            signal(sig) { signalNumber in
                let report = CrashReport(
                    id: UUID(),
                    timestamp: Date(),
                    errorType: "signal",
                    errorMessage: "Signal \(signalNumber)",
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n"),
                    deviceModel: CrashReporterService.deviceModel(),
                    osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                    appVersion: AppConfiguration.appVersion,
                    buildNumber: AppConfiguration.buildNumber,
                    context: ["signal": String(signalNumber)]
                )
                CrashReporterService.persistReportSync(report)
                // Re-raise with default handler
                Foundation.signal(signalNumber, SIG_DFL)
                raise(signalNumber)
            }
        }
    }

    // MARK: - Persistence

    func persistReport(_ report: CrashReport) {
        lock.lock()
        defer { lock.unlock() }
        let fileURL = storageDirectory.appendingPathComponent("\(report.id.uuidString).json")
        if let data = try? encoder.encode(report) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func loadPendingReports() -> [CrashReport] {
        lock.lock()
        defer { lock.unlock() }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: storageDirectory, includingPropertiesForKeys: nil
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> CrashReport? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(CrashReport.self, from: data)
            }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func deleteReport(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Static Helpers

    private static func persistReportSync(_ report: CrashReport) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("CrashReports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(report.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(report) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0) ?? "unknown"
            }
        }
    }
}
