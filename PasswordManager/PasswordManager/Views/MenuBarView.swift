//
//  MenuBarView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = VaultViewModel()
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingImportSheet = false
    @State private var entryToEdit: PasswordEntry?

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.appState {
            case .loading:
                ProgressView()
                    .padding()

            case .needsSetup:
                SetupView { password, confirm in
                    await viewModel.setupMasterPassword(password, confirmPassword: confirm)
                }

            case .locked:
                UnlockView { password in
                    await viewModel.attemptUnlock(masterPassword: password)
                }

            case .unlocked:
                unlockedView

            case .error(let message):
                VStack(spacing: 12) {
                    Text("⚠️")
                        .font(.system(size: 48))
                    Text(message)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        viewModel.checkInitialState()
                    }
                }
                .padding()
            }
        }
        .frame(width: Constants.UI.popoverWidth)
        .onReceive(viewModel.$searchQuery) { _ in
            viewModel.updateSearch()
        }
    }

    @ViewBuilder
    private var unlockedView: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(text: $viewModel.searchQuery)
                .padding(8)

            Divider()

            // Entry list
            EntryListView(
                entries: viewModel.filteredEntries,
                searchQuery: viewModel.searchQuery,
                onCopy: { entry in
                    viewModel.copyPassword(entry)
                },
                onOpenURL: { entry in
                    viewModel.openURL(entry)
                },
                onEdit: { entry in
                    entryToEdit = entry
                    showingEditSheet = true
                }
            )
            .frame(maxHeight: 400)

            Divider()

            // Bottom toolbar
            HStack(spacing: 16) {
                Button(action: { showingSettingsSheet = true }) {
                    Label("设置", systemImage: "gear")
                }
                .buttonStyle(.plain)
                .help("设置")

                Spacer()

                Button(action: { showingAddSheet = true }) {
                    Label("新增", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .help("新增密码")

                Button(action: { showingImportSheet = true }) {
                    Label("导入", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.plain)
                .help("导入")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEntryView { entry in
                viewModel.addEntry(
                    name: entry.name,
                    username: entry.username,
                    password: entry.password,
                    url: entry.url,
                    notes: entry.notes,
                    icon: entry.icon
                )
            }
        }
        .sheet(item: $entryToEdit) { entry in
            EditEntryView(entry: entry) { updated in
                viewModel.updateEntry(updated)
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(viewModel: viewModel)
        }
        .fileImporter(
            isPresented: $showingImportSheet,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        _ = await viewModel.importFromFile(url: url)
                    }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
