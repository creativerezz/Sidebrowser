//
//  MenuBarManager.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI
import AppKit
import Combine

/// Manages the menubar status item and menu
class MenuBarManager: NSObject, ObservableObject {
    @MainActor private var statusItem: NSStatusItem?
    private var appState: AppState
    @MainActor private var popoverManager: PopoverManager?
    @MainActor private var keyboardShortcutManager: KeyboardShortcutManager?

    @MainActor
    init(appState: AppState) {
        self.appState = appState
        super.init()
        self.popoverManager = PopoverManager(appState: appState)
        self.keyboardShortcutManager = KeyboardShortcutManager()
        setupMenuBar()
        setupGlobalKeyboardShortcut()
    }

    @MainActor
    private func setupGlobalKeyboardShortcut() {
        keyboardShortcutManager?.registerGlobalShortcut { [weak self] in
            guard let self = self,
                  let button = self.statusItem?.button,
                  let popoverManager = self.popoverManager else {
                return
            }

            popoverManager.toggle(relativeTo: button)
            self.appState.isVisible = popoverManager.isShown
        }
    }

    @MainActor
    func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusItem = statusItem else { return }

        // Set icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Sidebrowser")
            button.action = #selector(togglePanel)
            button.target = self
        }

        // Create menu
        statusItem.menu = createMenu()
    }

    @MainActor
    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        let showHideItem = NSMenuItem(
            title: "Show/Hide Browser",
            action: #selector(togglePanel),
            keyEquivalent: ""
        )
        showHideItem.target = self
        menu.addItem(showHideItem)

        menu.addItem(NSMenuItem.separator())

        let urlPromptItem = NSMenuItem(
            title: "Enter URL...",
            action: #selector(showURLPrompt),
            keyEquivalent: "l"
        )
        urlPromptItem.target = self
        menu.addItem(urlPromptItem)

        menu.addItem(NSMenuItem.separator())

        // Opacity submenu
        menu.addItem(createOpacitySubmenu())

        menu.addItem(NSMenuItem.separator())

        // Always on top toggle
        let alwaysOnTopItem = NSMenuItem(
            title: "Always on Top",
            action: #selector(toggleAlwaysOnTop),
            keyEquivalent: "t"
        )
        alwaysOnTopItem.target = self
        alwaysOnTopItem.state = appState.alwaysOnTop ? .on : .off
        menu.addItem(alwaysOnTopItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit Sidebrowser",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @MainActor
    private func createOpacitySubmenu() -> NSMenuItem {
        let opacityMenu = NSMenu()
        for opacity in [100, 90, 80, 70, 60, 50] {
            let item = NSMenuItem(
                title: "\(opacity)%",
                action: #selector(setOpacity(_:)),
                keyEquivalent: ""
            )
            item.tag = opacity
            item.target = self
            opacityMenu.addItem(item)
        }

        let opacityItem = NSMenuItem(
            title: "Opacity",
            action: nil,
            keyEquivalent: ""
        )
        opacityItem.submenu = opacityMenu
        return opacityItem
    }

    @MainActor
    @objc private func togglePanel() {
        guard let button = statusItem?.button,
              let popoverManager = popoverManager else {
            return
        }

        // Toggle popover visibility
        popoverManager.toggle(relativeTo: button)
        appState.isVisible = popoverManager.isShown
    }

    @MainActor
    @objc private func showURLPrompt() {
        let alert = NSAlert()
        alert.messageText = "Enter URL"
        alert.informativeText = "Enter the URL you want to visit:"
        alert.alertStyle = .informational

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = appState.currentURL.absoluteString
        alert.accessoryView = textField

        alert.addButton(withTitle: "Go")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            var urlString = textField.stringValue.trimmingCharacters(in: .whitespaces)

            // Add https:// if no scheme provided
            if !urlString.contains("://") {
                urlString = "https://" + urlString
            }

            if let url = URL(string: urlString) {
                appState.loadURL(url)
            }
        }
    }

    @MainActor
    @objc private func setOpacity(_ sender: NSMenuItem) {
        let opacity = Double(sender.tag) / 100.0
        appState.windowOpacity = opacity
    }

    @MainActor
    @objc private func toggleAlwaysOnTop() {
        appState.alwaysOnTop.toggle()

        // Update menu item state
        if let menu = statusItem?.menu {
            for item in menu.items where item.title == "Always on Top" {
                item.state = appState.alwaysOnTop ? .on : .off
            }
        }
    }

    @MainActor
    @objc private func openSettings() {
        // Create settings window manually for menubar app
        let settingsView = SettingsView().environmentObject(appState)
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Sidebrowser Settings"
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
