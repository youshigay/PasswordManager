//
//  Constants.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation

enum Constants {
    // MARK: - Storage
    enum Storage {
        static let appSupportPath = "Application Support/PasswordManager"
        static let vaultFileName = "vault.json"
        static let backupFileExtension = "bak"

        static var vaultURL: URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = appSupport.appendingPathComponent(appSupportPath)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder.appendingPathComponent(vaultFileName)
        }

        static var appSupportDirectory: URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return appSupport.appendingPathComponent(appSupportPath)
        }
    }

    // MARK: - Security
    enum Security {
        static let keychainService = "com.passwordmanager.vault"
        static let keychainAccount = "encryptedDEK"
        static let pbkdf2Iterations = 100_000
        static let keyLength = 32 // 256 bits
        static let saltLength = 16
        static let ivLength = 12 // GCM standard
    }

    // MARK: - Authentication
    enum Auth {
        static let minPasswordLength = 8
        static let maxFailedAttempts = 5
        static let lockoutDuration: TimeInterval = 300 // 5 minutes
        static let delayAfter3Failures: TimeInterval = 3
        static let delayAfter4Failures: TimeInterval = 15
    }

    // MARK: - Clipboard
    enum Clipboard {
        static let clearInterval: TimeInterval = 30
    }

    // MARK: - UI
    enum UI {
        static let popoverWidth: CGFloat = 360
        static let popoverHeight: CGFloat = 500
        static let rowHeight: CGFloat = 44
        static let defaultIcon = "🔒"
    }

    // MARK: - Import/Export
    enum ImportExport {
        static let currentVersion = 1
    }
}
