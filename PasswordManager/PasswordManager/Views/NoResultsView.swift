//
//  NoResultsView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct NoResultsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🔍")
                .font(.system(size: 48))

            Text("未找到匹配的密码")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
