//
//  WebViewWrapper.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI
import WebKit

// MARK: - Notification Names for WebView Control

extension Notification.Name {
    static let webViewGoBack = Notification.Name("webViewGoBack")
    static let webViewGoForward = Notification.Name("webViewGoForward")
    static let webViewReload = Notification.Name("webViewReload")
    static let webViewStopLoading = Notification.Name("webViewStopLoading")
}

/// SwiftUI wrapper for WKWebView with navigation support
struct WebViewWrapper: NSViewRepresentable {
    @Binding var url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    // Shared WKWebView instance for memory optimization
    private static var sharedWebView: WKWebView?
    
    func makeNSView(context: Context) -> WKWebView {
        // Reuse existing webview or create new one
        if let existingWebView = Self.sharedWebView {
            existingWebView.navigationDelegate = context.coordinator
            existingWebView.uiDelegate = context.coordinator
            return existingWebView
        }
        
        let configuration = WKWebViewConfiguration()
        // JavaScript is enabled by default in modern WebKit
        // Use WKWebpagePreferences.allowsContentJavaScript on a per-navigation basis if needed
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Store for reuse
        Self.sharedWebView = webView
        
        // Set up notification observers
        context.coordinator.setupNotificationObservers(for: webView)
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only load if URL has changed
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // Update navigation state
        DispatchQueue.main.async {
            canGoBack = webView.canGoBack
            canGoForward = webView.canGoForward
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewWrapper
        private var observers: [NSObjectProtocol] = []
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }
        
        deinit {
            // Remove notification observers
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }
        
        func setupNotificationObservers(for webView: WKWebView) {
            // Clear old observers
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
            
            // Go back
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: .webViewGoBack,
                    object: nil,
                    queue: .main
                ) { _ in
                    if webView.canGoBack {
                        webView.goBack()
                    }
                }
            )
            
            // Go forward
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: .webViewGoForward,
                    object: nil,
                    queue: .main
                ) { _ in
                    if webView.canGoForward {
                        webView.goForward()
                    }
                }
            )
            
            // Reload
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: .webViewReload,
                    object: nil,
                    queue: .main
                ) { _ in
                    webView.reload()
                }
            )
            
            // Stop loading
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: .webViewStopLoading,
                    object: nil,
                    queue: .main
                ) { _ in
                    webView.stopLoading()
                }
            )
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            
            // Update URL in case of redirects
            if let currentURL = webView.url {
                parent.url = currentURL
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("Navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            // Allow all navigation for MVP
            // Future: Add content blocking rules here
            return .allow
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle popup windows - open in same webview for MVP
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
    
    /// Clean up shared resources when app terminates
    static func cleanup() {
        sharedWebView?.stopLoading()
        sharedWebView?.navigationDelegate = nil
        sharedWebView?.uiDelegate = nil
        sharedWebView = nil
    }
}
