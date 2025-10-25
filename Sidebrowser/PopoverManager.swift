//
//  PopoverManager.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI
import AppKit
import Combine

/// Manages the popover window that appears below the menu bar icon
@MainActor
class PopoverManager: NSObject, ObservableObject {
    private var popover: NSPopover?
    private let appState: AppState
    @Published var isShown = false

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    /// Shows the popover below the status bar button
    func show(relativeTo button: NSStatusBarButton) {
        // Create popover if needed
        if popover == nil {
            let popover = NSPopover()
            popover.contentSize = NSSize(
                width: appState.windowSize.width,
                height: appState.windowSize.height
            )
            popover.behavior = .transient
            popover.animates = true
            popover.contentViewController = NSHostingController(
                rootView: FloatingPanelView()
                    .environmentObject(appState)
            )
            self.popover = popover
        }

        // Show popover
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                isShown = false
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isShown = true

                // Activate app to receive keyboard input
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    /// Hides the popover
    func hide() {
        popover?.performClose(nil)
        isShown = false
    }

    /// Toggles popover visibility
    func toggle(relativeTo button: NSStatusBarButton) {
        show(relativeTo: button)
    }
}
