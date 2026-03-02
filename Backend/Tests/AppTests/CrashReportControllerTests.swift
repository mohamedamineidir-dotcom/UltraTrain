@testable import App
import XCTVapor
import Fluent

final class CrashReportControllerTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await createTestApp()
    }

    override func tearDown() async throws {
        app.shutdown()
        app = nil
    }

    // MARK: - Helpers

    private func validCrashReport(
        id: UUID = UUID(),
        context: [String: String]? = nil
    ) -> CrashReportDTO {
        CrashReportDTO(
            id: id,
            timestamp: Date(),
            errorType: "EXC_BAD_ACCESS",
            errorMessage: "Attempted to dereference a null pointer",
            stackTrace: "0x1234 in someFunction()\n0x5678 in anotherFunction()",
            deviceModel: "iPhone15,2",
            osVersion: "17.4",
            appVersion: "1.0.0",
            buildNumber: "42",
            context: context
        )
    }

    // MARK: - POST /crashes

    func testCreateCrashReport_valid_returnsCreated() async throws {
        try await app.test(.POST, "v1/crashes", beforeRequest: { req in
            try req.content.encode(self.validCrashReport())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        // Verify stored in database
        let count = try await CrashReportModel.query(on: app.db).count()
        XCTAssertEqual(count, 1)
    }

    func testCreateCrashReport_withContext_storesContext() async throws {
        let context = ["screen": "RunTracking", "userId": "anonymous-123"]

        try await app.test(.POST, "v1/crashes", beforeRequest: { req in
            try req.content.encode(self.validCrashReport(context: context))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        let report = try await CrashReportModel.query(on: app.db).first()
        XCTAssertNotNil(report?.contextJson)
        XCTAssertTrue(report!.contextJson!.contains("RunTracking"))
    }

    func testCreateCrashReport_withoutContext_succeeds() async throws {
        try await app.test(.POST, "v1/crashes", beforeRequest: { req in
            try req.content.encode(self.validCrashReport(context: nil))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        let report = try await CrashReportModel.query(on: app.db).first()
        XCTAssertNil(report?.contextJson)
    }

    func testCreateCrashReport_storesAllFields() async throws {
        let clientId = UUID()

        try await app.test(.POST, "v1/crashes", beforeRequest: { req in
            try req.content.encode(self.validCrashReport(id: clientId))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        let report = try await CrashReportModel.query(on: app.db).first()
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.clientId, clientId)
        XCTAssertEqual(report!.errorType, "EXC_BAD_ACCESS")
        XCTAssertEqual(report!.errorMessage, "Attempted to dereference a null pointer")
        XCTAssertEqual(report!.deviceModel, "iPhone15,2")
        XCTAssertEqual(report!.osVersion, "17.4")
        XCTAssertEqual(report!.appVersion, "1.0.0")
        XCTAssertEqual(report!.buildNumber, "42")
    }

    func testCreateCrashReport_truncatesLongStackTrace() async throws {
        let longTrace = String(repeating: "A", count: 20000)

        let dto = CrashReportDTO(
            id: UUID(),
            timestamp: Date(),
            errorType: "Error",
            errorMessage: "Test",
            stackTrace: longTrace,
            deviceModel: "iPhone15,2",
            osVersion: "17.4",
            appVersion: "1.0.0",
            buildNumber: "1",
            context: nil
        )

        try await app.test(.POST, "v1/crashes", beforeRequest: { req in
            try req.content.encode(dto)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })

        let report = try await CrashReportModel.query(on: app.db).first()
        XCTAssertEqual(report!.stackTrace.count, 10000)
    }

    func testCreateCrashReport_noAuthRequired() async throws {
        // Crash reports should work without authentication
        try await app.test(.POST, "v1/crashes", beforeRequest: { req in
            try req.content.encode(self.validCrashReport())
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
        })
    }

    func testCreateCrashReport_multipleReports_allStored() async throws {
        for _ in 0..<3 {
            try await app.test(.POST, "v1/crashes", beforeRequest: { req in
                try req.content.encode(self.validCrashReport())
            }, afterResponse: { _ in })
        }

        let count = try await CrashReportModel.query(on: app.db).count()
        XCTAssertEqual(count, 3)
    }
}
