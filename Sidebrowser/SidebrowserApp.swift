//
//  SidebrowserApp.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI

@main
struct SidebrowserApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var menuBarManager: MenuBarManager
    
    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        _menuBarManager = StateObject(wrappedValue: MenuBarManager(appState: state))
    }
    
    var body: some Scene {
        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
