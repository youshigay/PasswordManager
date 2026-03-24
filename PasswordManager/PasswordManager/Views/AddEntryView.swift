//
//  AddEntryView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI
import AppKit

// Helper to focus first responder on macOS
struct FirstResponder: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Use a longer delay to ensure the sheet window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let window = view.window else { return }
            if let contentView = window.contentView {
                if let textField = findTextField(in: contentView) {
                    window.makeFirstResponder(textField)
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func findTextField(in view: NSView) -> NSTextField? {
        for subview in view.subviews {
            if let textField = subview as? NSTextField, textField.isEditable {
                return textField
            }
            if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }
}

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var icon = ""
    @State private var showPassword = false

    let onSave: (PasswordEntry) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("新增密码")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("名称")
                        .frame(width: 60, alignment: .trailing)
                    TextField("必填", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("用户名")
                        .frame(width: 60, alignment: .trailing)
                    TextField("必填", text: $username)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("密码")
                        .frame(width: 60, alignment: .trailing)
                    HStack(spacing: 4) {
                        Group {
                            if showPassword {
                                TextField("必填", text: $password)
                            } else {
                                SecureField("必填", text: $password)
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    Text("网址")
                        .frame(width: 60, alignment: .trailing)
                    TextField("可选", text: $url)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("备注")
                        .frame(width: 60, alignment: .trailing)
                    TextField("可选", text: $notes)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("图标")
                        .frame(width: 60, alignment: .trailing)
                    TextField("emoji", text: $icon)
                        .textFieldStyle(.roundedBorder)
                }
            }

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
        .frame(width: 380)
        .background(FirstResponder())
    }
}
