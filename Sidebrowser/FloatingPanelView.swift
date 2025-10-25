//
//  FloatingPanelView.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI
import WebKit

/// Main floating browser window content
struct FloatingPanelView: View {
    @EnvironmentObject var appState: AppState

    @State private var isLoading = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var urlText = ""
    @State private var isEditingURL = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation toolbar
            HStack(spacing: 10) {
                // Navigation controls group
                HStack(spacing: 6) {
                    // Back button
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(canGoBack ? .primary : .secondary.opacity(0.5))
                            .frame(width: 24, height: 24)
                    }
                    .disabled(!canGoBack)
                    .buttonStyle(.plain)
                    .help("Go Back")

                    // Forward button
                    Button(action: goForward) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(canGoForward ? .primary : .secondary.opacity(0.5))
                            .frame(width: 24, height: 24)
                    }
                    .disabled(!canGoForward)
                    .buttonStyle(.plain)
                    .help("Go Forward")

                    // Refresh/Stop button
                    Button(action: refresh) {
                        Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help(isLoading ? "Stop Loading" : "Reload Page")
                }
                .padding(.horizontal, 4)

                // URL field
                TextField("Enter URL or search", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onAppear {
                        urlText = appState.currentURL.absoluteString
                    }
                    .onChange(of: appState.currentURL) { _, newURL in
                        if !isEditingURL {
                            urlText = newURL.absoluteString
                        }
                    }
                    .onSubmit {
                        loadURL()
                    }

                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 20, height: 20)
                } else {
                    Spacer()
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(.secondary.opacity(0.2)),
                alignment: .bottom
            )
            
            // Web content
            WebViewWrapper(
                url: $appState.currentURL,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            minWidth: 320,
            idealWidth: appState.windowSize.width,
            maxWidth: .infinity,
            minHeight: 480,
            idealHeight: appState.windowSize.height,
            maxHeight: .infinity
        )
    }

    // MARK: - Navigation Actions
    
    private func goBack() {
        // Send notification to webview
        NotificationCenter.default.post(name: .webViewGoBack, object: nil)
    }
    
    private func goForward() {
        // Send notification to webview
        NotificationCenter.default.post(name: .webViewGoForward, object: nil)
    }
    
    private func refresh() {
        if isLoading {
            NotificationCenter.default.post(name: .webViewStopLoading, object: nil)
        } else {
            NotificationCenter.default.post(name: .webViewReload, object: nil)
        }
    }
    
    private func loadURL() {
        var urlString = urlText.trimmingCharacters(in: .whitespaces)
        
        // Add https:// if no scheme provided
        if !urlString.contains("://") {
            urlString = "https://" + urlString
        }
        
        if let url = URL(string: urlString) {
            appState.currentURL = url
        }
        
        isEditingURL = false
    }
}

#Preview {
    FloatingPanelView()
        .environmentObject(AppState())
        .frame(width: 400, height: 600)
}
