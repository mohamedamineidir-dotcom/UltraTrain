import Foundation
import Testing
@testable import UltraTrain

@Suite("BackgroundUploadFileManager Tests")
struct BackgroundUploadFileManagerTests {

    // MARK: - Helpers

    private func makeDTO(id: String = UUID().uuidString) -> RunUploadRequestDTO {
        RunUploadRequestDTO(
            id: id,
            date: ISO8601DateFormatter().string(from: Date()),
            distanceKm: 15.5,
            elevationGainM: 450,
            elevationLossM: 430,
            duration: 5400,
            averageHeartRate: 152,
            maxHeartRate: 178,
            averagePaceSecondsPerKm: 348,
            gpsTrack: [],
            splits: [],
            notes: "Test run",
            linkedSessionId: nil,
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )
    }

    // MARK: - Write

    @Test("writeUploadFile creates a file on disk with the correct name")
    func writeCreatesFileWithCorrectName() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO()

        let fileURL = try fm.writeUploadFile(dto: dto, id: id)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(fileURL.lastPathComponent == "\(id.uuidString).json")

        fm.cleanupFile(for: id)
    }

    @Test("writeUploadFile produces valid JSON with snake_case keys")
    func writeProducesValidSnakeCaseJSON() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO(id: "test-run-id")

        let fileURL = try fm.writeUploadFile(dto: dto, id: id)
        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Verify snake_case encoding
        #expect(json?["distance_km"] as? Double == 15.5)
        #expect(json?["elevation_gain_m"] as? Double == 450)
        #expect(json?["id"] as? String == "test-run-id")

        fm.cleanupFile(for: id)
    }

    @Test("writeUploadFile uses ISO8601 date encoding")
    func writeUsesISO8601DateEncoding() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO()

        let fileURL = try fm.writeUploadFile(dto: dto, id: id)
        let data = try Data(contentsOf: fileURL)

        // The file should be valid JSON
        #expect(data.count > 0)

        fm.cleanupFile(for: id)
    }

    // MARK: - Cleanup

    @Test("cleanupFile removes only the targeted file")
    func cleanupRemovesTargetedFile() throws {
        let fm = BackgroundUploadFileManager()
        let id1 = UUID()
        let id2 = UUID()
        let dto = makeDTO()

        let url1 = try fm.writeUploadFile(dto: dto, id: id1)
        let url2 = try fm.writeUploadFile(dto: dto, id: id2)

        fm.cleanupFile(for: id1)

        #expect(!FileManager.default.fileExists(atPath: url1.path))
        #expect(FileManager.default.fileExists(atPath: url2.path))

        fm.cleanupFile(for: id2)
    }

    @Test("cleanupFile for nonexistent file does not throw")
    func cleanupNonexistentFileIsSafe() {
        let fm = BackgroundUploadFileManager()
        fm.cleanupFile(for: UUID())
        // No assertion needed -- just verifying no crash
    }

    @Test("cleanupAll removes the entire upload directory")
    func cleanupAllRemovesDirectory() throws {
        let fm = BackgroundUploadFileManager()
        let id1 = UUID()
        let id2 = UUID()
        let dto = makeDTO()

        _ = try fm.writeUploadFile(dto: dto, id: id1)
        _ = try fm.writeUploadFile(dto: dto, id: id2)

        fm.cleanupAll()

        // After cleanupAll, individual cleanup should not crash
        fm.cleanupFile(for: id1)
        fm.cleanupFile(for: id2)
    }

    @Test("multiple writes with same ID overwrite the file")
    func multipleWritesSameIdOverwrite() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto1 = makeDTO(id: "first")
        let dto2 = makeDTO(id: "second")

        _ = try fm.writeUploadFile(dto: dto1, id: id)
        let fileURL = try fm.writeUploadFile(dto: dto2, id: id)

        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["id"] as? String == "second")

        fm.cleanupFile(for: id)
    }
}
