import Foundation
import Security

/// The Google API key for the online role-play, in the iOS Keychain. The item is readable after the
/// first unlock and never leaves this phone: not in backups, not in the progress export.
enum KeychainStore {
    private static let service = "io.github.li1000v2.mammamia.gemini"
    private static let account = "google-api-key"

    static func readKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                AppLog.shared.write("Keychain: reading the key failed (\(status))")
            }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// The OSStatus, errSecSuccess (0) when saved.
    @discardableResult
    static func saveKey(_ key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: Data(key.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        if status != errSecSuccess {
            AppLog.shared.write("Keychain: saving the key failed (\(status))")
        }
        return status
    }

    static func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
