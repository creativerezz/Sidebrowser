//
//  WindowAccessor.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI
import AppKit

/// Utility to access and configure NSWindow properties from SwiftUI
/// Required for macOS 14 compatibility where .windowLevel() modifier is not available
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update callback if window changes
        DispatchQueue.main.async {
            self.callback(nsView.window)
        }
    }
}
