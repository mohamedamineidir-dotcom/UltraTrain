import Foundation
import os

enum FileProtectionManager {

    static var defaultStoreDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    static func applyProtection(to directory: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: directory.path
            )
            if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    try fileManager.setAttributes(
                        [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                        ofItemAtPath: fileURL.path
                    )
                }
            }
            Logger.security.info("Applied file protection to: \(directory.lastPathComponent)")
        } catch {
            Logger.security.error("Failed to apply file protection: \(error)")
        }
    }
}
