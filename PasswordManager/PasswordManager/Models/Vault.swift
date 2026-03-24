//
//  Vault.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation

struct Vault: Codable {
    let schemaVersion: Int
    var entries: [PasswordEntry]

    init(entries: [PasswordEntry] = []) {
        self.schemaVersion = Constants.ImportExport.currentVersion
        self.entries = entries
    }

    mutating func add(_ entry: PasswordEntry) {
        entries.append(entry)
    }

    mutating func update(_ entry: PasswordEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        }
    }

    mutating func delete(_ entry: PasswordEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func search(_ query: String) -> [PasswordEntry] {
        guard !query.isEmpty else { return entries }
        let lowercased = query.lowercased()
        return entries.filter { entry in
            entry.name.lowercased().contains(lowercased) ||
            entry.username.lowercased().contains(lowercased) ||
            (entry.notes?.lowercased().contains(lowercased) ?? false)
        }
    }

    func findDuplicate(name: String, username: String, excludingId: UUID? = nil) -> PasswordEntry? {
        let key = "\(name.lowercased())|\(username.lowercased())"
        return entries.first { entry in
            entry.uniqueKey == key && entry.id != excludingId
        }
    }
}
