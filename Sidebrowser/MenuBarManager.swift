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

    @MainActor
    init(appState: AppState) {
        self.appState = appState
        super.init()
        self.popoverManager = PopoverManager(appState: appState)
        setupMenuBar()
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
        menu.addItem(opacityItem)
        
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
        
        statusItem.menu = menu
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
            for item in menu.items {
                if item.title == "Always on Top" {
                    item.state = appState.alwaysOnTop ? .on : .off
                }
            }
        }
    }
    
    @MainActor
    @objc private func openSettings() {
        // Open Settings window using standard macOS method
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        } else {
            // Fallback: Try to activate settings via keyboard shortcut simulation
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }

        // Ensure app is active
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @MainActor
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
