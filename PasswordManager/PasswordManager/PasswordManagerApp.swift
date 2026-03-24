//
//  PasswordManagerApp.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

@main
struct PasswordManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
