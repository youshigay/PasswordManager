//
//  KeychainService.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedStatus(OSStatus)
}

class KeychainService {
    static let shared = KeychainService()
    private init() {}

    // MARK: - Store Encrypted DEK with Salt

    func storeCredentials(encryptedDEK: Data, salt: Data) throws {
        // Store encrypted DEK
        let dekQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Security.keychainService,
            kSecAttrAccount as String: "encryptedDEK",
            kSecValueData as String: encryptedDEK,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(dekQuery as CFDictionary)
        let dekStatus = SecItemAdd(dekQuery as CFDictionary, nil)
        guard dekStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(dekStatus)
        }

        // Store salt
        let saltQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Security.keychainService,
            kSecAttrAccount as String: "salt",
            kSecValueData as String: salt,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(saltQuery as CFDictionary)
        let saltStatus = SecItemAdd(saltQuery as CFDictionary, nil)
        guard saltStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(saltStatus)
        }
    }

    // MARK: - Retrieve Credentials

    func getCredentials() throws -> (encryptedDEK: Data, salt: Data) {
        let encryptedDEK = try getData(account: "encryptedDEK")
        let salt = try getData(account: "salt")
        return (encryptedDEK, salt)
    }

    // MARK: - Check if Setup Complete

    func hasCredentials() -> Bool {
        do {
            _ = try getCredentials()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Delete All Credentials

    func deleteCredentials() throws {
        let accounts = ["encryptedDEK", "salt"]
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Constants.Security.keychainService,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Private Helpers

    private func getData(account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Security.keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.itemNotFound
        }

        return data
    }
}
