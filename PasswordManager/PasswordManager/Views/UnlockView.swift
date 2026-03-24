//
//  UnlockView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct UnlockView: View {
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""

    let onUnlock: (String) async -> Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("🔐")
                .font(.system(size: 48))

            Text("解锁密码管理器")
                .font(.title2)
                .fontWeight(.semibold)

            SecureField("输入主密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
                .onSubmit {
                    Task {
                        await attemptUnlock()
                    }
                }

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button("解锁") {
                Task {
                    await attemptUnlock()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: Constants.UI.popoverWidth)
    }

    private func attemptUnlock() async {
        let success = await onUnlock(password)
        if !success {
            showError = true
            password = ""
        }
    }
}
