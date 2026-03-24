//
//  EntryListView.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

struct EntryListView: View {
    let entries: [PasswordEntry]
    let searchQuery: String
    let onCopy: (PasswordEntry) -> Void
    let onOpenURL: (PasswordEntry) -> Void
    let onEdit: (PasswordEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                if searchQuery.isEmpty {
                    EmptyStateView()
                } else {
                    NoResultsView()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            EntryRowView(
                                entry: entry,
                                onCopy: { onCopy(entry) },
                                onOpenURL: { onOpenURL(entry) },
                                onEdit: { onEdit(entry) }
                            )
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
