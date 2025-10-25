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
    @State private var showBookmarks = false
    @State private var showSearchSuggestions = false
    @FocusState private var isURLFieldFocused: Bool
    
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
                    .keyboardShortcut("[", modifiers: .command)
                    .help("Go Back (⌘[)")

                    // Forward button
                    Button(action: goForward) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(canGoForward ? .primary : .secondary.opacity(0.5))
                            .frame(width: 24, height: 24)
                    }
                    .disabled(!canGoForward)
                    .buttonStyle(.plain)
                    .keyboardShortcut("]", modifiers: .command)
                    .help("Go Forward (⌘])")

                    // Refresh/Stop button
                    Button(action: refresh) {
                        Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("r", modifiers: .command)
                    .help(isLoading ? "Stop Loading" : "Reload Page (⌘R)")
                }
                .padding(.horizontal, 4)

                // URL field with bookmark button
                HStack(spacing: 4) {
                    TextField("Enter URL or search", text: $urlText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .focused($isURLFieldFocused)
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

                    // Bookmark star button
                    Button(action: {
                        appState.toggleBookmark()
                    }) {
                        Image(systemName: appState.isCurrentURLBookmarked() ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(appState.isCurrentURLBookmarked() ? .yellow : .secondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(appState.isCurrentURLBookmarked() ? "Remove Bookmark" : "Add Bookmark")

                    // Bookmarks menu button
                    Button(action: {
                        showBookmarks.toggle()
                    }) {
                        Image(systemName: "book")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("Show Bookmarks")
                    .popover(isPresented: $showBookmarks, arrowEdge: .bottom) {
                        BookmarksView()
                            .environmentObject(appState)
                            .frame(width: 300, height: 400)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )

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

        // Check if it's a URL or a search query
        if urlString.contains(".") && !urlString.contains(" ") {
            // Likely a URL - add https:// if no scheme provided
            if !urlString.contains("://") {
                urlString = "https://" + urlString
            }

            if let url = URL(string: urlString) {
                appState.currentURL = url
            }
        } else {
            // Treat as search query
            let encodedQuery = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
            let searchURLString = appState.searchEngine.searchURL + encodedQuery

            if let searchURL = URL(string: searchURLString) {
                appState.currentURL = searchURL
            }
        }

        isEditingURL = false
        isURLFieldFocused = false
    }
}

// MARK: - Bookmarks View

struct BookmarksView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bookmarks")
                    .font(.headline)
                Spacer()
                Text("\(appState.bookmarks.count)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))

            Divider()

            // Bookmarks list
            if appState.bookmarks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Bookmarks Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Click the star icon in the URL bar to save bookmarks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(appState.bookmarks) { bookmark in
                            BookmarkRow(bookmark: bookmark)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    appState.loadURL(bookmark.url)
                                }
                        }
                    }
                }
            }
        }
    }
}

struct BookmarkRow: View {
    @EnvironmentObject var appState: AppState
    let bookmark: Bookmark

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.system(size: 13))
                    .lineLimit(1)

                Text(bookmark.url.absoluteString)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                appState.removeBookmark(bookmark)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove Bookmark")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            // Add hover effect if needed
        }
    }
}


#Preview {
    FloatingPanelView()
        .environmentObject(AppState())
        .frame(width: 400, height: 600)
}
