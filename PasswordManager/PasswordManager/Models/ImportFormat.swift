//
//  ImportFormat.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation

struct ImportFormat: Codable {
    let version: Int
    let entries: [ImportEntry]

    struct ImportEntry: Codable {
        let name: String
        let username: String
        let password: String
        let url: String?
        let notes: String?
        let icon: String?

        func toPasswordEntry() -> PasswordEntry {
            PasswordEntry(
                name: name,
                username: username,
                password: password,
                url: url,
                notes: notes,
                icon: icon
            )
        }
    }
}

struct ExportFormat: Codable {
    let version: Int
    let entries: [ExportEntry]

    struct ExportEntry: Codable {
        let name: String
        let username: String
        let password: String
        let url: String?
        let notes: String?
        let icon: String?
    }

    static func from(vault: Vault) -> ExportFormat {
        let entries = vault.entries.map { entry in
            ExportEntry(
                name: entry.name,
                username: entry.username,
                password: entry.password,
                url: entry.url,
                notes: entry.notes,
                icon: entry.icon
            )
        }
        return ExportFormat(version: Constants.ImportExport.currentVersion, entries: entries)
    }
}
