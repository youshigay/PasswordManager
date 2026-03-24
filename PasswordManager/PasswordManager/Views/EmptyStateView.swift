//
//  EmptyStateView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🔐")
                .font(.system(size: 48))

            Text("暂无密码条目")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("点击下方「+」添加第一个密码")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
