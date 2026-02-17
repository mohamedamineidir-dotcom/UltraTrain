import Foundation
import Security
import os

enum KeychainManager {
    private static let logger = Logger.app

    // MARK: - Data Operations

    static func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ultratrain.app",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("Keychain save failed for key '\(key)': \(status)")
            throw KeychainError.saveFailed(status: status)
        }
    }

    static func load(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ultratrain.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            logger.error("Keychain load failed for key '\(key)': \(status)")
            throw KeychainError.loadFailed(status: status)
        }
    }

    static func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ultratrain.app"
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Codable Convenience

    static func save<T: Encodable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        try save(data, for: key)
    }

    static func load<T: Decodable>(_ type: T.Type, for key: String) throws -> T? {
        guard let data = try load(for: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - KeychainError

enum KeychainError: Error, LocalizedError {
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from Keychain (status: \(status))"
        }
    }
}
