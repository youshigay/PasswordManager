//
//  VaultService.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation
import CryptoKit

enum VaultError: Error, LocalizedError {
    case vaultNotFound
    case vaultCorrupted
    case keychainError
    case encryptionError
    case importFailed(String)
    case exportFailed
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .vaultNotFound:
            return "保险库未找到"
        case .vaultCorrupted:
            return "保险库数据损坏"
        case .keychainError:
            return "密钥访问失败"
        case .encryptionError:
            return "加密/解密失败"
        case .importFailed(let reason):
            return "导入失败: \(reason)"
        case .exportFailed:
            return "导出失败"
        case .invalidPassword:
            return "密码无效"
        }
    }
}

class VaultService {
    static let shared = VaultService()

    private let cryptoService = CryptoService.shared
    private let keychainService = KeychainService.shared

    private init() {}

    // MARK: - Vault Status

    var isVaultSetup: Bool {
        keychainService.hasCredentials()
    }

    var needsInitialSetup: Bool {
        !keychainService.hasCredentials()
    }

    var vaultExists: Bool {
        FileManager.default.fileExists(atPath: Constants.Storage.vaultURL.path)
    }

    // MARK: - Initial Setup

    func setupVault(masterPassword: String) throws {
        // 1. Generate DEK
        let dek = cryptoService.generateDEK()

        // 2. Generate salt and derive master key
        let salt = cryptoService.generateSalt()
        let masterKey = try cryptoService.deriveKey(from: masterPassword, salt: salt)

        // 3. Encrypt DEK with master key
        let encryptedDEK = try cryptoService.encryptDEK(dek, using: masterKey)

        // 4. Store encrypted DEK and salt in Keychain
        try keychainService.storeCredentials(encryptedDEK: encryptedDEK, salt: salt)

        // 5. Create empty vault and save
        let vault = Vault()
        try saveVault(vault, using: dek)
    }

    // MARK: - Unlock

    func unlockVault(masterPassword: String) throws -> (vault: Vault, dek: SymmetricKey) {
        // 1. Get encrypted DEK and salt from Keychain
        let (encryptedDEK, salt) = try keychainService.getCredentials()

        // 2. Derive master key from password
        let masterKey = try cryptoService.deriveKey(from: masterPassword, salt: salt)

        // 3. Decrypt DEK with master key
        let dek = try cryptoService.decryptDEK(encryptedDEK, using: masterKey)

        // 4. Load and decrypt vault
        let vault = try loadVault(using: dek)

        return (vault, dek)
    }

    // MARK: - Save/Load

    func saveVault(_ vault: Vault, using dek: SymmetricKey) throws {
        let vaultURL = Constants.Storage.vaultURL

        // Ensure directory exists
        let directory = vaultURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Backup existing file
        if FileManager.default.fileExists(atPath: vaultURL.path) {
            let backupURL = vaultURL.appendingPathExtension(Constants.Storage.backupFileExtension)
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: vaultURL, to: backupURL)
        }

        // Encrypt and save
        let encryptedData = try cryptoService.encryptVault(vault, using: dek)
        try encryptedData.write(to: vaultURL)
    }

    private func loadVault(using dek: SymmetricKey) throws -> Vault {
        let vaultURL = Constants.Storage.vaultURL

        guard FileManager.default.fileExists(atPath: vaultURL.path) else {
            return Vault()
        }

        let encryptedData = try Data(contentsOf: vaultURL)

        do {
            return try cryptoService.decryptVault(encryptedData, using: dek)
        } catch {
            throw VaultError.vaultCorrupted
        }
    }

    // MARK: - Import/Export

    func importFromFile(url: URL, into vault: inout Vault) throws -> ImportResult {
        // Read file
        let data = try Data(contentsOf: url)

        // Parse JSON
        let decoder = JSONDecoder()
        let importFormat: ImportFormat

        do {
            importFormat = try decoder.decode(ImportFormat.self, from: data)
        } catch {
            throw VaultError.importFailed("JSON 格式无效: \(error.localizedDescription)")
        }

        // Validate version
        guard importFormat.version == Constants.ImportExport.currentVersion else {
            throw VaultError.importFailed("不支持的版本: \(importFormat.version)")
        }

        var imported = 0
        var skipped = 0
        var duplicates: [(name: String, username: String)] = []

        // Import entries
        for entry in importFormat.entries {
            if vault.findDuplicate(name: entry.name, username: entry.username) != nil {
                skipped += 1
                duplicates.append((entry.name, entry.username))
            } else {
                vault.add(entry.toPasswordEntry())
                imported += 1
            }
        }

        return ImportResult(imported: imported, skipped: skipped, duplicates: duplicates)
    }

    func exportVault(_ vault: Vault) throws -> URL {
        let exportFormat = ExportFormat.from(vault: vault)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exportFormat)

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "passwords_export_\(timestamp).json"
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try data.write(to: exportURL)
        return exportURL
    }

    // MARK: - Reset

    func resetVault() throws {
        try keychainService.deleteCredentials()
        try? FileManager.default.removeItem(at: Constants.Storage.vaultURL)
    }
}

// MARK: - Import Result

struct ImportResult {
    let imported: Int
    let skipped: Int
    let duplicates: [(name: String, username: String)]
}
