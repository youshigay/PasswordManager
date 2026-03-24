//
//  EditEntryView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var username: String
    @State private var password: String
    @State private var url: String
    @State private var notes: String
    @State private var icon: String

    let entry: PasswordEntry
    let onSave: (PasswordEntry) -> Void

    init(entry: PasswordEntry, onSave: @escaping (PasswordEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _name = State(initialValue: entry.name)
        _username = State(initialValue: entry.username)
        _password = State(initialValue: entry.password)
        _url = State(initialValue: entry.url ?? "")
        _notes = State(initialValue: entry.notes ?? "")
        _icon = State(initialValue: entry.icon ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("编辑密码")
                .font(.headline)

            Form {
                TextField("名称", text: $name)
                TextField("用户名", text: $username)
                SecureField("密码", text: $password)
                TextField("网址", text: $url)
                TextField("备注", text: $notes)
                TextField("图标 (emoji)", text: $icon)
            }
            .formStyle(.grouped)

            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.escape)

                Spacer()

                Button("保存") {
                    var updated = entry
                    updated.update(
                        name: name,
                        username: username,
                        password: password,
                        url: url,
                        notes: notes,
                        icon: icon.isEmpty ? nil : icon
                    )
                    onSave(updated)
                    dismiss()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
