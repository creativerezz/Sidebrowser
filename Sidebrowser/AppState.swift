//
//  AppState.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI
import Combine

/// Main application state for the floating browser window
@MainActor
class AppState: ObservableObject {
    @Published var currentURL: URL
    @Published var isVisible: Bool = false
    @Published var windowOpacity: Double = 0.95
    @Published var windowSize: CGSize
    @Published var windowPosition: CGPoint?
    @Published var alwaysOnTop: Bool = true
    @Published var snapToEdges: Bool = true

    init() {
        // Default to Apple's homepage
        self.currentURL = URL(string: "https://www.apple.com")!

        // Optimized default size for top-floating window
        self.windowSize = CGSize(width: 480, height: 700)
    }

    /// Toggles window visibility
    func toggleVisibility() {
        isVisible.toggle()
    }

    /// Loads a new URL and ensures window is visible
    func loadURL(_ url: URL) {
        currentURL = url
        if !isVisible {
            isVisible = true
        }
    }

    /// Resets window position to default (top center)
    func resetPosition() {
        windowPosition = nil
    }
}
