//
//  EntryRowView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct EntryRowView: View {
    let entry: PasswordEntry
    let onCopy: () -> Void
    let onOpenURL: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.icon ?? Constants.UI.defaultIcon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(entry.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Copy button
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("复制密码")

            // Open URL button
            if entry.url != nil {
                Button(action: onOpenURL) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("打开网址并复制密码")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: Constants.UI.rowHeight)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onEdit()
        }
        .contextMenu {
            Button("复制密码") { onCopy() }
            if entry.url != nil {
                Button("打开网址") { onOpenURL() }
            }
            Divider()
            Button("编辑...") { onEdit() }
        }
    }
}
