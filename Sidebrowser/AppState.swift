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
    @Published var windowOpacity: Double
    @Published var windowSize: CGSize
    @Published var windowPosition: CGPoint?
    @Published var alwaysOnTop: Bool
    @Published var snapToEdges: Bool
    @Published var searchEngine: SearchEngine = .google
    @Published var bookmarks: [Bookmark] = []
    @Published var isPrivateBrowsing: Bool = false
    @Published var downloadHistory: [Download] = []

    private let defaults = UserDefaults.standard

    // UserDefaults keys
    private enum Keys {
        static let lastURL = "lastURL"
        static let windowOpacity = "windowOpacity"
        static let windowWidth = "windowWidth"
        static let windowHeight = "windowHeight"
        static let alwaysOnTop = "alwaysOnTop"
        static let snapToEdges = "snapToEdges"
        static let searchEngine = "searchEngine"
        static let bookmarks = "bookmarks"
    }

    init() {
        // Load saved URL or default to Apple's homepage
        if let urlString = defaults.string(forKey: Keys.lastURL),
           let url = URL(string: urlString) {
            self.currentURL = url
        } else {
            self.currentURL = URL(string: "https://www.apple.com")!
        }

        // Load saved opacity or default to 95%
        let savedOpacity = defaults.double(forKey: Keys.windowOpacity)
        self.windowOpacity = savedOpacity > 0 ? savedOpacity : 0.95

        // Load saved window size or default
        let savedWidth = defaults.double(forKey: Keys.windowWidth)
        let savedHeight = defaults.double(forKey: Keys.windowHeight)
        if savedWidth > 0 && savedHeight > 0 {
            self.windowSize = CGSize(width: savedWidth, height: savedHeight)
        } else {
            self.windowSize = CGSize(width: 480, height: 700)
        }

        // Load saved preferences
        self.alwaysOnTop = defaults.bool(forKey: Keys.alwaysOnTop) || !defaults.objectIsForced(forKey: Keys.alwaysOnTop)
        self.snapToEdges = defaults.bool(forKey: Keys.snapToEdges)

        // Load search engine
        if let engineRaw = defaults.string(forKey: Keys.searchEngine),
           let engine = SearchEngine(rawValue: engineRaw) {
            self.searchEngine = engine
        }

        // Load bookmarks
        if let data = defaults.data(forKey: Keys.bookmarks),
           let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
            self.bookmarks = bookmarks
        }

        // Set up auto-save observers
        setupObservers()
    }

    private func setupObservers() {
        // Save URL changes (debounced)
        $currentURL
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] url in
                self?.defaults.set(url.absoluteString, forKey: Keys.lastURL)
            }
            .store(in: &cancellables)

        // Save opacity changes
        $windowOpacity
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] opacity in
                self?.defaults.set(opacity, forKey: Keys.windowOpacity)
            }
            .store(in: &cancellables)

        // Save window size changes
        $windowSize
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] size in
                self?.defaults.set(size.width, forKey: Keys.windowWidth)
                self?.defaults.set(size.height, forKey: Keys.windowHeight)
            }
            .store(in: &cancellables)

        // Save preferences
        $alwaysOnTop
            .sink { [weak self] value in
                self?.defaults.set(value, forKey: Keys.alwaysOnTop)
            }
            .store(in: &cancellables)

        $snapToEdges
            .sink { [weak self] value in
                self?.defaults.set(value, forKey: Keys.snapToEdges)
            }
            .store(in: &cancellables)

        $searchEngine
            .sink { [weak self] engine in
                self?.defaults.set(engine.rawValue, forKey: Keys.searchEngine)
            }
            .store(in: &cancellables)

        $bookmarks
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] bookmarks in
                if let data = try? JSONEncoder().encode(bookmarks) {
                    self?.defaults.set(data, forKey: Keys.bookmarks)
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

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

    /// Adds a bookmark
    func addBookmark(_ bookmark: Bookmark) {
        if !bookmarks.contains(where: { $0.url == bookmark.url }) {
            bookmarks.append(bookmark)
        }
    }

    /// Removes a bookmark
    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
    }

    /// Toggles bookmark for current URL
    func toggleBookmark() {
        if let index = bookmarks.firstIndex(where: { $0.url == currentURL }) {
            bookmarks.remove(at: index)
        } else {
            let bookmark = Bookmark(title: currentURL.host ?? currentURL.absoluteString, url: currentURL)
            bookmarks.append(bookmark)
        }
    }

    /// Checks if current URL is bookmarked
    func isCurrentURLBookmarked() -> Bool {
        bookmarks.contains { $0.url == currentURL }
    }
}

// MARK: - Supporting Types

enum SearchEngine: String, Codable, CaseIterable {
    case google = "Google"
    case duckduckgo = "DuckDuckGo"
    case bing = "Bing"
    case brave = "Brave"

    var searchURL: String {
        switch self {
        case .google: return "https://www.google.com/search?q="
        case .duckduckgo: return "https://duckduckgo.com/?q="
        case .bing: return "https://www.bing.com/search?q="
        case .brave: return "https://search.brave.com/search?q="
        }
    }
}

struct Bookmark: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var url: URL
    var createdAt: Date

    init(id: UUID = UUID(), title: String, url: URL, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.url = url
        self.createdAt = createdAt
    }
}

struct Download: Identifiable, Codable {
    let id: UUID
    var filename: String
    var url: URL
    var progress: Double
    var isComplete: Bool
    var createdAt: Date

    init(id: UUID = UUID(), filename: String, url: URL, progress: Double = 0, isComplete: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.filename = filename
        self.url = url
        self.progress = progress
        self.isComplete = isComplete
        self.createdAt = createdAt
    }
}
