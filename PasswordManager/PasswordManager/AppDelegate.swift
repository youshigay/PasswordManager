//
//  AppDelegate.swift
//  PasswordManager
//
//  Created by michaels on 2026/3/24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate: applicationDidFinishLaunching called")
        setupStatusItem()
        print("✅ AppDelegate: Status item setup complete")
    }

    private func setupStatusItem() {
        print("🔧 Setting up status item...")
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use a more visible icon
            if let image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "Password Manager") {
                image.isTemplate = true  // Makes it adapt to menu bar appearance
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
            print("✅ Status item button configured")
        } else {
            print("❌ Failed to get status item button")
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: Constants.UI.popoverWidth, height: Constants.UI.popoverHeight)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
        print("✅ Popover created")
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
