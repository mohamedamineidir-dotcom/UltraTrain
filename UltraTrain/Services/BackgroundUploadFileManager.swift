import Foundation
import os

struct BackgroundUploadFileManager: Sendable {
    private static let directoryName = "BackgroundUploads"

    private var uploadDirectory: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent(Self.directoryName)
    }

    func writeUploadFile(dto: RunUploadRequestDTO, id: UUID) throws -> URL {
        let dir = uploadDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)

        let fileURL = dir.appendingPathComponent("\(id.uuidString).json")
        try data.write(to: fileURL, options: .atomic)

        Logger.backgroundUpload.debug("Wrote upload file: \(fileURL.lastPathComponent) (\(data.count) bytes)")
        return fileURL
    }

    func cleanupFile(for id: UUID) {
        let fileURL = uploadDirectory.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
        Logger.backgroundUpload.debug("Cleaned up upload file: \(fileURL.lastPathComponent)")
    }

    func cleanupAll() {
        try? FileManager.default.removeItem(at: uploadDirectory)
        Logger.backgroundUpload.debug("Cleaned up all background upload files")
    }
}
