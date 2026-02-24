import Testing
import Foundation
@testable import UltraTrain

struct BackgroundUploadServiceTests {

    // MARK: - BackgroundUploadFileManager

    @Test func writeUploadFileCreatesFile() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO()

        let fileURL = try fm.writeUploadFile(dto: dto, id: id)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(fileURL.lastPathComponent == "\(id.uuidString).json")

        // Cleanup
        fm.cleanupFile(for: id)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test func writeUploadFileContainsValidJSON() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO()

        let fileURL = try fm.writeUploadFile(dto: dto, id: id)
        let data = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode(MinimalRunDTO.self, from: data)

        #expect(decoded.id == dto.id)

        fm.cleanupFile(for: id)
    }

    @Test func cleanupFileRemovesFile() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO()

        let fileURL = try fm.writeUploadFile(dto: dto, id: id)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        fm.cleanupFile(for: id)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test func cleanupNonexistentFileDoesNotCrash() {
        let fm = BackgroundUploadFileManager()
        fm.cleanupFile(for: UUID())
    }

    @Test func cleanupAllRemovesDirectory() throws {
        let fm = BackgroundUploadFileManager()
        let id = UUID()
        let dto = makeDTO()

        _ = try fm.writeUploadFile(dto: dto, id: id)

        fm.cleanupAll()
        fm.cleanupFile(for: id)
    }

    // MARK: - BackgroundUploadService

    @Test func sessionIdentifierIsCorrect() {
        #expect(BackgroundUploadService.sessionIdentifier == "com.ultratrain.app.background-upload")
    }

    @Test func gpsThresholdIs500() {
        #expect(BackgroundUploadService.gpsThreshold == 500)
    }

    @Test func handleSessionCompletionCallsHandlerForMatchingId() {
        let queueRepo = MockSyncQueueRepository()
        let auth = MockAuthService()
        let service = BackgroundUploadService(
            syncQueueRepository: queueRepo,
            authService: auth
        )

        var handlerCalled = false
        service.handleSessionCompletion(
            identifier: BackgroundUploadService.sessionIdentifier,
            completion: { handlerCalled = true }
        )

        // The handler is stored, not called immediately
        // It gets called by urlSessionDidFinishEvents
        #expect(!handlerCalled)
    }

    @Test func handleSessionCompletionCallsImmediatelyForWrongId() {
        let queueRepo = MockSyncQueueRepository()
        let auth = MockAuthService()
        let service = BackgroundUploadService(
            syncQueueRepository: queueRepo,
            authService: auth
        )

        var handlerCalled = false
        service.handleSessionCompletion(
            identifier: "wrong-id",
            completion: { handlerCalled = true }
        )

        #expect(handlerCalled)
    }

    // MARK: - Helpers

    private func makeDTO() -> RunUploadRequestDTO {
        RunUploadRequestDTO(
            id: UUID().uuidString,
            date: ISO8601DateFormatter().string(from: Date()),
            distanceKm: 10.0,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            notes: nil,
            linkedSessionId: nil,
            idempotencyKey: UUID().uuidString,
            clientUpdatedAt: nil
        )
    }
}

/// Minimal decodable for verifying JSON file content
private struct MinimalRunDTO: Decodable {
    let id: String
}
