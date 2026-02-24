import Foundation
import os

final class DeviceIntegrityChecker: DeviceIntegrityCheckerProtocol, @unchecked Sendable {

    func isDeviceCompromised() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let compromised = hasSuspiciousFiles()
            || canWriteOutsideSandbox()
            || hasSuspiciousDylibs()

        if compromised {
            Logger.security.warning("Device integrity check: device appears compromised")
        }
        return compromised
        #endif
    }

    // MARK: - Private

    private func hasSuspiciousFiles() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/usr/bin/ssh",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/libexec/cydia",
            "/var/cache/apt",
            "/var/lib/cydia",
            "/bin/bash",
            "/usr/sbin/frida-server"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    private func canWriteOutsideSandbox() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    private func hasSuspiciousDylibs() -> Bool {
        let suspiciousLibs = [
            "MobileSubstrate",
            "SSLKillSwitch",
            "FridaGadget",
            "cycript",
            "libcycript"
        ]
        let count = _dyld_image_count()
        for i in 0..<count {
            guard let name = _dyld_get_image_name(i) else { continue }
            let imageName = String(cString: name)
            for lib in suspiciousLibs {
                if imageName.contains(lib) {
                    return true
                }
            }
        }
        return false
    }
}
