//
//  SettingsView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: VaultViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirm = false

    var body: some View {
        VStack(spacing: 20) {
            Text("设置")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("快捷键")
                    Spacer()
                    Text("⌘⇧P")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("剪贴板清除")
                    Spacer()
                    Text("\(Int(Constants.Clipboard.clearInterval))秒")
                        .foregroundColor(.secondary)
                }

                Divider()

                Button("导出数据") {
                    if let url = viewModel.exportToFile() {
                        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                    }
                }

                Button("清空所有数据", role: .destructive) {
                    showingResetConfirm = true
                }
            }
            .frame(width: 280)

            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.escape)
            }
        }
        .padding()
        .frame(width: 350)
        .alert("确认清空", isPresented: $showingResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task {
                    try? await viewModel.resetAllData()
                    dismiss()
                }
            }
        } message: {
            Text("此操作将删除所有密码数据，无法恢复。确定要继续吗？")
        }
    }
}
