//
//  SetupView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct SetupView: View {
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false

    let onSetup: (String, String) async -> Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("🔐")
                .font(.system(size: 48))

            Text("设置主密码")
                .font(.title2)
                .fontWeight(.semibold)

            Text("请设置一个主密码用于保护您的密码数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                SecureField("主密码", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("确认密码", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(width: 250)

            if showError {
                Text("密码设置失败，请重试")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button("完成设置") {
                Task {
                    let success = await onSetup(password, confirmPassword)
                    showError = !success
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(password.count < Constants.Auth.minPasswordLength || password != confirmPassword)
        }
        .padding(24)
        .frame(width: Constants.UI.popoverWidth)
    }
}
