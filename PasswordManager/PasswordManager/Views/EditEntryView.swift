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
    @State private var showPassword = false

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

            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("名称") {
                    TextField("必填", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                LabeledContent("用户名") {
                    TextField("必填", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                LabeledContent("密码") {
                    HStack(spacing: 4) {
                        Group {
                            if showPassword {
                                TextField("必填", text: $password)
                            } else {
                                SecureField("必填", text: $password)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 196)

                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                LabeledContent("网址") {
                    TextField("可选", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                LabeledContent("备注") {
                    TextField("可选", text: $notes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }

                LabeledContent("图标") {
                    TextField("emoji", text: $icon)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }
            }

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
        .frame(width: 380)
    }
}
