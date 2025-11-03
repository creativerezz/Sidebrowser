# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Sidebrowser** is a lightweight macOS menu bar browser application that provides a popover-style web browser accessible from the system menu bar. The app uses SwiftUI for UI, AppKit for menu bar integration, and WebKit for rendering web content.

- **Platform**: macOS 14.0+
- **Framework**: SwiftUI + AppKit
- **Build System**: Xcode
- **Target**: Sidebrowser (single target)

## Building & Running

### Opening the Project
```bash
open Sidebrowser.xcodeproj
```

### Building from Command Line
```bash
# Build for Debug
xcodebuild -project Sidebrowser.xcodeproj -scheme Sidebrowser -configuration Debug

# Build for Release
xcodebuild -project Sidebrowser.xcodeproj -scheme Sidebrowser -configuration Release
```

### Running in Xcode
- Select the "Sidebrowser" scheme
- Press ⌘R to build and run
- The app will appear in the menu bar (no dock icon)

## Architecture Overview

### State Management Pattern

The app uses **Combine-based reactive state management** with automatic UserDefaults persistence:

- **`AppState`**: Central `@MainActor ObservableObject` that holds all application state
  - Uses `@Published` properties with Combine for reactivity
  - Auto-saves to UserDefaults with `.debounce()` for performance
  - All state changes propagate via Combine publishers
  - Distributed to views via `.environmentObject(appState)`

### Manager Pattern

Three specialized manager classes coordinate different aspects of the app:

1. **`MenuBarManager`**:
   - Owns the `NSStatusItem` (menu bar icon)
   - Creates and manages the NSMenu
   - Coordinates between PopoverManager and AppState
   - Handles menu item actions (@objc methods)
   - Creates Settings window programmatically

2. **`PopoverManager`**:
   - Manages NSPopover lifecycle
   - Controls popover show/hide behavior
   - Uses `.transient` behavior for auto-dismiss
   - Positions popover below menu bar button

3. **`KeyboardShortcutManager`**:
   - Registers global keyboard shortcut (⌥⌘Space)
   - Uses CGEvent tap for system-wide key interception
   - **Requires Accessibility permissions** (prompts user on first launch)
   - Uses Carbon framework for key code handling

### WebView Architecture

**Shared WKWebView Pattern**: The app uses a singleton WKWebView instance for memory optimization:

```swift
// WebViewWrapper.swift
private static var sharedWebView: WKWebView?
```

**NotificationCenter-based Communication**: SwiftUI controls WebView via notifications:

```swift
// FloatingPanelView → WebViewWrapper communication
NotificationCenter.default.post(name: .webViewGoBack, object: nil)
NotificationCenter.default.post(name: .webViewReload, object: nil)
```

This pattern decouples SwiftUI buttons from the NSView-based WKWebView.

## Key Files & Responsibilities

### Core Application
- **`SidebrowserApp.swift`**: App entry point, creates Settings Scene only (no WindowGroup)
- **`AppState.swift`**: Central state management with Combine + UserDefaults persistence

### UI Components
- **`FloatingPanelView.swift`**: Main browser UI (navigation bar + WebView)
- **`SettingsView.swift`**: Tabbed settings window (General, Appearance, Shortcuts, About)
- **`WebViewWrapper.swift`**: NSViewRepresentable wrapper for WKWebView
- **`VisualEffectView.swift`**: NSVisualEffectView wrapper for native blur effects

### Managers
- **`MenuBarManager.swift`**: Menu bar status item and menu management
- **`PopoverManager.swift`**: Popover window lifecycle
- **`KeyboardShortcutManager.swift`**: Global keyboard shortcut handling

### Utilities
- **`WindowAccessor.swift`**: Helper for accessing NSWindow from SwiftUI (legacy)

## Important Patterns & Conventions

### MainActor Usage
All manager classes and state mutations are marked `@MainActor` to ensure UI thread safety:

```swift
@MainActor
class MenuBarManager: NSObject, ObservableObject { ... }
```

### Popover-Based Architecture
The app uses **NSPopover**, not a floating NSWindow:
- Popover appears below menu bar icon when clicked
- `.transient` behavior auto-dismisses when clicking outside
- Replaces earlier floating window implementation (see CHANGELOG.md)

### Settings Window Pattern
Settings window is created programmatically, not via Scene:

```swift
// MenuBarManager.swift
let hostingController = NSHostingController(rootView: settingsView)
let window = NSWindow(contentViewController: hostingController)
```

This is necessary for menu bar-only apps without a primary window.

### UserDefaults Auto-Save
State changes are debounced and auto-saved to prevent excessive writes:

```swift
// AppState.swift
$currentURL
    .debounce(for: .seconds(1), scheduler: RunLoop.main)
    .sink { [weak self] url in
        self?.defaults.set(url.absoluteString, forKey: Keys.lastURL)
    }
    .store(in: &cancellables)
```

### WebView Memory Optimization
A shared WKWebView instance is reused to prevent memory overhead:
- Created once on first use
- Reused across popover show/hide cycles
- Cleanup via `WebViewWrapper.cleanup()` when app terminates

## Development Notes

### Accessibility Permissions
The global keyboard shortcut (⌥⌘Space) requires Accessibility permissions:
- `KeyboardShortcutManager` uses `AXIsProcessTrustedWithOptions()` to check/prompt
- Uses CGEvent tap to intercept system-wide keyboard events
- Falls back gracefully if permissions denied (menu bar click still works)

### Navigation State Updates
WebView navigation state (canGoBack, canGoForward) is updated both:
1. In `updateNSView()` for SwiftUI-initiated changes
2. In `WKNavigationDelegate` callbacks for user-initiated navigation

This dual-update ensures UI stays in sync regardless of navigation source.

### Notification Cleanup
WebViewWrapper properly cleans up NotificationCenter observers in deinit to prevent leaks:

```swift
deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
}
```

### Common Pitfalls
- Don't create multiple WKWebView instances (use the shared instance)
- Always use `@MainActor` for UI-related managers
- Settings window must be created programmatically (Scene-based approach won't work for menu bar apps)
- Remember to update both the popover state AND appState.isVisible when toggling visibility
