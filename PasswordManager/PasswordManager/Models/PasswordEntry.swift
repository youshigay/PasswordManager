//
//  PasswordEntry.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation

struct PasswordEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var username: String
    var password: String
    var url: String?
    var notes: String?
    var icon: String?
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    // 注意：name + username 组合应唯一，用于导入时检测重复
    var uniqueKey: String {
        "\(name.lowercased())|\(username.lowercased())"
    }

    init(
        id: UUID = UUID(),
        name: String,
        username: String,
        password: String,
        url: String? = nil,
        notes: String? = nil,
        icon: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.url = url
        self.notes = notes
        self.icon = icon ?? Constants.UI.defaultIcon
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    mutating func update(
        name: String? = nil,
        username: String? = nil,
        password: String? = nil,
        url: String? = nil,
        notes: String? = nil,
        icon: String? = nil,
        isFavorite: Bool? = nil
    ) {
        if let name = name { self.name = name }
        if let username = username { self.username = username }
        if let password = password { self.password = password }
        if let url = url { self.url = url.isEmpty ? nil : url }
        if let notes = notes { self.notes = notes.isEmpty ? nil : notes }
        if let icon = icon { self.icon = icon }
        if let isFavorite = isFavorite { self.isFavorite = isFavorite }
        self.updatedAt = Date()
    }
}
