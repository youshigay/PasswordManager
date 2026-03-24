//
//  VaultViewModel.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit

enum AppState {
    case loading
    case needsSetup
    case locked
    case unlocked
    case error(String)
}

@MainActor
class VaultViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var appState: AppState = .loading
    @Published var vault: Vault?
    @Published var searchQuery = ""
    @Published var filteredEntries: [PasswordEntry] = []
    @Published var errorMessage: String?
    @Published var showingAddEntry = false
    @Published var showingSettings = false
    @Published var showingImport = false
    @Published var entryToEdit: PasswordEntry?

    // MARK: - Private Properties

    private var dek: SymmetricKey?
    private let vaultService = VaultService.shared
    private let biometricService = BiometricService.shared

    private var failedAttempts = 0
    private var lockoutUntil: Date?

    // Debounce for search
    private var searchDebounceTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var isLocked: Bool {
        if case .locked = appState { return true }
        return false
    }

    var isUnlocked: Bool {
        if case .unlocked = appState { return true }
        return false
    }

    var biometricTypeName: String {
        biometricService.biometricTypeName
    }

    var isBiometricAvailable: Bool {
        biometricService.isBiometricAvailable
    }

    // MARK: - Initialization

    init() {
        checkInitialState()
    }

    // MARK: - State Management

    func checkInitialState() {
        if vaultService.needsInitialSetup {
            appState = .needsSetup
        } else {
            appState = .locked
        }
    }

    // MARK: - Setup

    func setupMasterPassword(_ password: String, confirmPassword: String) async -> Bool {
        guard password == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            return false
        }

        guard password.count >= Constants.Auth.minPasswordLength else {
            errorMessage = "密码至少需要 \(Constants.Auth.minPasswordLength) 个字符"
            return false
        }

        do {
            try vaultService.setupVault(masterPassword: password)
            let (vault, dek) = try vaultService.unlockVault(masterPassword: password)
            self.vault = vault
            self.dek = dek
            self.filteredEntries = vault.entries
            appState = .unlocked
            return true
        } catch {
            errorMessage = "设置失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Unlock

    func attemptUnlock(masterPassword: String) async -> Bool {
        // Check lockout
        if let lockoutUntil = lockoutUntil, Date() < lockoutUntil {
            let remaining = Int(lockoutUntil.timeIntervalSince(Date()))
            errorMessage = "已锁定，请 \(remaining) 秒后重试"
            return false
        }

        // Apply delays
        if failedAttempts >= 4 {
            try? await Task.sleep(nanoseconds: UInt64(Constants.Auth.delayAfter4Failures * 1_000_000_000))
        } else if failedAttempts >= 3 {
            try? await Task.sleep(nanoseconds: UInt64(Constants.Auth.delayAfter3Failures * 1_000_000_000))
        }

        do {
            let (vault, dek) = try vaultService.unlockVault(masterPassword: masterPassword)
            self.vault = vault
            self.dek = dek
            self.filteredEntries = vault.entries
            self.failedAttempts = 0
            self.lockoutUntil = nil
            appState = .unlocked
            return true
        } catch {
            failedAttempts += 1

            if failedAttempts >= Constants.Auth.maxFailedAttempts {
                lockoutUntil = Date().addingTimeInterval(Constants.Auth.lockoutDuration)
                errorMessage = "失败次数过多，已锁定 5 分钟"
            } else {
                errorMessage = "密码错误，剩余 \(Constants.Auth.maxFailedAttempts - failedAttempts) 次机会"
            }
            return false
        }
    }

    // MARK: - Lock

    func lock() {
        vault = nil
        dek = nil
        filteredEntries = []
        searchQuery = ""
        appState = .locked
    }

    // MARK: - Search

    func updateSearch() {
        // Cancel previous debounce task
        searchDebounceTask?.cancel()

        // Create new debounce task (1 second delay)
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            guard !Task.isCancelled else { return }

            guard let vault = vault else {
                await MainActor.run { filteredEntries = [] }
                return
            }
            let results = vault.search(searchQuery)
            await MainActor.run { filteredEntries = results }
        }
    }

    func searchImmediately() {
        searchDebounceTask?.cancel()
        guard let vault = vault else {
            filteredEntries = []
            return
        }
        filteredEntries = vault.search(searchQuery)
    }

    // MARK: - Entry Management

    func addEntry(name: String, username: String, password: String, url: String?, notes: String?, icon: String?) {
        guard var vault = vault, let dek = dek else { return }

        let entry = PasswordEntry(
            name: name,
            username: username,
            password: password,
            url: url,
            notes: notes,
            icon: icon
        )

        vault.add(entry)

        do {
            try vaultService.saveVault(vault, using: dek)
            self.vault = vault
            updateSearch()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }

    func updateEntry(_ entry: PasswordEntry) {
        guard var vault = vault, let dek = dek else { return }

        vault.update(entry)

        do {
            try vaultService.saveVault(vault, using: dek)
            self.vault = vault
            updateSearch()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }

    func deleteEntry(_ entry: PasswordEntry) {
        guard var vault = vault, let dek = dek else { return }

        vault.delete(entry)

        do {
            try vaultService.saveVault(vault, using: dek)
            self.vault = vault
            updateSearch()
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Clipboard

    func copyPassword(_ entry: PasswordEntry) {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(entry.password, forType: .string)

        // Clear after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Clipboard.clearInterval) { [weak self] in
            if pasteboard.changeCount == changeCount {
                pasteboard.clearContents()
            }
        }
    }

    func openURL(_ entry: PasswordEntry) {
        guard let urlString = entry.url, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
        copyPassword(entry)
    }

    // MARK: - Import/Export

    func importFromFile(url: URL) async -> ImportResult? {
        guard var vault = vault, let dek = dek else { return nil }

        do {
            let result = try vaultService.importFromFile(url: url, into: &vault)
            try vaultService.saveVault(vault, using: dek)
            self.vault = vault
            updateSearch()
            return result
        } catch {
            errorMessage = "导入失败: \(error.localizedDescription)"
            return nil
        }
    }

    func exportToFile() -> URL? {
        guard let vault = vault else { return nil }

        do {
            return try vaultService.exportVault(vault)
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Reset

    func resetAllData() async throws {
        try vaultService.resetVault()
        vault = nil
        dek = nil
        filteredEntries = []
        appState = .needsSetup
    }
}
