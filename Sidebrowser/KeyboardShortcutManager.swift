//
//  KeyboardShortcutManager.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import AppKit
import Carbon

/// Manages global keyboard shortcuts
class KeyboardShortcutManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var onToggle: (() -> Void)?

    /// Registers the global keyboard shortcut ⌥⌘Space
    func registerGlobalShortcut(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        // Request accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        var trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Wait a bit for permissions if not initially granted
        var attempts = 0
        while !trusted && attempts < 5 {
            sleep(1)
            trusted = AXIsProcessTrustedWithOptions(nil)
            attempts += 1
            print("Checking accessibility permissions... attempt \(attempts)")
        }

        if !trusted {
            print("⚠️ Accessibility permissions not granted. Global shortcut won't work.")
            print("Please grant accessibility permissions to the app in System Preferences > Security & Privacy > Privacy")
            return
        }

        // Create event tap for key events
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Check if it's Option+Command+Space
                let flags = event.flags
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                // Space key code is 49
                // Check for Option (⌥) and Command (⌘) modifiers
                if keyCode == 49 &&
                   flags.contains(.maskCommand) &&
                   flags.contains(.maskAlternate) &&
                   !flags.contains(.maskControl) &&
                   !flags.contains(.maskShift) {

                    // Call the toggle callback on main thread
                    DispatchQueue.main.async {
                        let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon!).takeUnretainedValue()
                        manager.onToggle?()
                    }

                    // Consume the event (don't pass it on)
                    return nil
                }

                // Pass through other events
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = eventTap

        // Add event tap to run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.runLoopSource = runLoopSource

        print("✅ Global keyboard shortcut registered: ⌥⌘Space")
    }

    /// Unregisters the global keyboard shortcut
    func unregisterGlobalShortcut() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        print("❌ Global keyboard shortcut unregistered")
    }

    deinit {
        unregisterGlobalShortcut()
    }
}
