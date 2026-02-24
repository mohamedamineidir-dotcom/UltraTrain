import Testing
import Foundation
@testable import UltraTrain

struct FileProtectionManagerTests {

    @Test func defaultStoreDirectoryIsValid() {
        let directory = FileProtectionManager.defaultStoreDirectory
        #expect(!directory.path.isEmpty)
        #expect(directory.path.contains("Application Support") || directory.path.contains("ApplicationSupport"))
    }

    @Test func applyProtectionDoesNotThrowOnTempDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Write a test file
        let testFile = tempDir.appendingPathComponent("test.txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // Should not throw
        FileProtectionManager.applyProtection(to: tempDir)

        // Verify directory still exists
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
    }
}
