//
//  AddEntryView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var icon = ""

    let onSave: (PasswordEntry) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("新增密码")
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
                    let entry = PasswordEntry(
                        name: name,
                        username: username,
                        password: password,
                        url: url.isEmpty ? nil : url,
                        notes: notes.isEmpty ? nil : notes,
                        icon: icon.isEmpty ? nil : icon
                    )
                    onSave(entry)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(name.isEmpty || username.isEmpty || password.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
    }
}
