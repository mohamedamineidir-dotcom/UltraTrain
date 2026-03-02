import Foundation
import Testing
@testable import UltraTrain

@Suite("CrashReporterService Tests")
struct CrashReporterServiceTests {

    private func makeTestDirectory() -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("CrashReporterTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }

    private func makeReport(
        id: UUID = UUID(),
        errorType: String = "caught",
        errorMessage: String = "Test error"
    ) -> CrashReport {
        CrashReport(
            id: id,
            timestamp: Date(),
            errorType: errorType,
            errorMessage: errorMessage,
            stackTrace: "frame1\nframe2\nframe3",
            deviceModel: "arm64",
            osVersion: "18.2",
            appVersion: "1.0.0",
            buildNumber: "1",
            context: ["key": "value"]
        )
    }

    @Test("Persist report writes JSON file to disk")
    func persistReport() throws {
        let dir = makeTestDirectory()
        let report = makeReport()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(report)
        let fileURL = dir.appendingPathComponent("\(report.id.uuidString).json")
        try data.write(to: fileURL, options: .atomic)

        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        #expect(exists)

        try? FileManager.default.removeItem(at: dir)
    }

    @Test("Load pending reports returns persisted reports sorted by timestamp")
    func loadPendingReports() throws {
        let dir = makeTestDirectory()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let older = CrashReport(
            id: UUID(), timestamp: Date(timeIntervalSince1970: 1000),
            errorType: "caught", errorMessage: "older",
            stackTrace: "", deviceModel: "arm64", osVersion: "18.2",
            appVersion: "1.0.0", buildNumber: "1", context: [:]
        )
        let newer = CrashReport(
            id: UUID(), timestamp: Date(timeIntervalSince1970: 2000),
            errorType: "caught", errorMessage: "newer",
            stackTrace: "", deviceModel: "arm64", osVersion: "18.2",
            appVersion: "1.0.0", buildNumber: "1", context: [:]
        )

        try encoder.encode(newer).write(
            to: dir.appendingPathComponent("\(newer.id.uuidString).json"), options: .atomic
        )
        try encoder.encode(older).write(
            to: dir.appendingPathComponent("\(older.id.uuidString).json"), options: .atomic
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        let reports = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> CrashReport? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(CrashReport.self, from: data)
            }
            .sorted { $0.timestamp < $1.timestamp }

        #expect(reports.count == 2)
        #expect(reports[0].errorMessage == "older")
        #expect(reports[1].errorMessage == "newer")

        try? FileManager.default.removeItem(at: dir)
    }

    @Test("Delete report removes file from disk")
    func deleteReport() throws {
        let dir = makeTestDirectory()
        let report = makeReport()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let fileURL = dir.appendingPathComponent("\(report.id.uuidString).json")
        try encoder.encode(report).write(to: fileURL, options: .atomic)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        try FileManager.default.removeItem(at: fileURL)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))

        try? FileManager.default.removeItem(at: dir)
    }

    @Test("CrashReport contains expected fields and no PII")
    func reportFields() {
        let report = makeReport(errorType: "signal", errorMessage: "Signal 11")
        #expect(report.errorType == "signal")
        #expect(report.errorMessage == "Signal 11")
        #expect(report.deviceModel == "arm64")
        #expect(report.appVersion == "1.0.0")
        #expect(report.buildNumber == "1")
        #expect(report.context["key"] == "value")
        #expect(!report.stackTrace.isEmpty)
    }

    @Test("CrashReport is Codable round-trip")
    func codableRoundTrip() throws {
        let report = makeReport()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(report)
        let decoded = try decoder.decode(CrashReport.self, from: data)

        #expect(decoded.id == report.id)
        #expect(decoded.errorType == report.errorType)
        #expect(decoded.errorMessage == report.errorMessage)
        #expect(decoded.deviceModel == report.deviceModel)
        #expect(decoded.context == report.context)
    }

    @Test("MockCrashReporter tracks calls correctly")
    @MainActor
    func mockTracksCalls() async {
        let mock = MockCrashReporter()
        mock.start()
        mock.reportError(NSError(domain: "test", code: 1), context: ["screen": "dashboard"])
        await mock.uploadPendingReports()

        #expect(mock.startCallCount == 1)
        #expect(mock.reportedErrors.count == 1)
        #expect(mock.reportedErrors[0].context["screen"] == "dashboard")
        #expect(mock.uploadCallCount == 1)
    }

    @Test("Device model returns non-empty string")
    func deviceModel() {
        let model = CrashReporterService.deviceModel()
        #expect(!model.isEmpty)
        #expect(model != "unknown")
    }
}
