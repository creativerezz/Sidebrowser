//
//  SettingsView.swift
//  Sidebrowser
//
//  Created by Reza Jafar on 10/24/25.
//

import SwiftUI

/// Main settings view with tabbed interface
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            KeyboardShortcutsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 550, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var defaultURL: String = ""

    var body: some View {
        Form {
            Section {
                LabeledContent("Default Homepage") {
                    TextField("https://www.example.com", text: $defaultURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                        .onAppear {
                            defaultURL = appState.currentURL.absoluteString
                        }
                        .onSubmit {
                            updateDefaultURL()
                        }
                }

                Button("Set Current Page as Homepage") {
                    defaultURL = appState.currentURL.absoluteString
                }
                .buttonStyle(.link)
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Always on Top", isOn: $appState.alwaysOnTop)
                    .help("Keep browser window above all other windows")

                Toggle("Snap to Screen Edges", isOn: $appState.snapToEdges)
                    .help("Window snaps when moved near screen edges")

                HStack {
                    Text("Window Position:")
                    Spacer()
                    Button("Reset to Top Center") {
                        appState.resetPosition()
                    }
                    .buttonStyle(.borderless)
                }
            } header: {
                Text("Window Behavior")
            }

            Section {
                LabeledContent("Default Window Size") {
                    HStack(spacing: 8) {
                        TextField("Width", value: Binding(
                            get: { Int(appState.windowSize.width) },
                            set: { appState.windowSize.width = CGFloat($0) }
                        ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)

                        Text("×")
                            .foregroundColor(.secondary)

                        TextField("Height", value: Binding(
                            get: { Int(appState.windowSize.height) },
                            set: { appState.windowSize.height = CGFloat($0) }
                        ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)

                        Text("px")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Common Sizes:")
                    Spacer()
                    Button("Small (400×600)") {
                        appState.windowSize = CGSize(width: 400, height: 600)
                    }
                    .buttonStyle(.borderless)

                    Button("Medium (480×700)") {
                        appState.windowSize = CGSize(width: 480, height: 700)
                    }
                    .buttonStyle(.borderless)

                    Button("Large (600×900)") {
                        appState.windowSize = CGSize(width: 600, height: 900)
                    }
                    .buttonStyle(.borderless)
                }
            } header: {
                Text("Window Size")
            }
        }
        .formStyle(.grouped)
    }

    private func updateDefaultURL() {
        guard let url = URL(string: defaultURL) else { return }
        appState.currentURL = url
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Window Opacity")
                        Spacer()
                        Text("\(Int(appState.windowOpacity * 100))%")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }

                    Slider(value: $appState.windowOpacity, in: 0.3...1.0) {
                        Text("Opacity")
                    } minimumValueLabel: {
                        Text("30%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Quick Presets:")
                    Spacer()
                    ForEach([0.5, 0.7, 0.85, 0.95, 1.0], id: \.self) { opacity in
                        Button("\(Int(opacity * 100))%") {
                            appState.windowOpacity = opacity
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("Transparency")
            } footer: {
                Text("Lower opacity allows you to see content behind the browser window")
                    .font(.caption)
            }

            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Dark mode automatically supported")
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Follows system appearance settings")
                }
            } header: {
                Text("Theme")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Keyboard Shortcuts

struct KeyboardShortcutsView: View {
    var body: some View {
        Form {
            Section {
                ShortcutRow(key: "⌘ L", description: "Enter URL from menu bar")
                ShortcutRow(key: "⌘ T", description: "Toggle 'Always on Top'")
                ShortcutRow(key: "⌘ ,", description: "Open Settings")
                ShortcutRow(key: "⌘ Q", description: "Quit Sidebrowser")
            } header: {
                Text("Menu Bar Shortcuts")
            }

            Section {
                ShortcutRow(key: "⌘ [", description: "Go Back", available: false)
                ShortcutRow(key: "⌘ ]", description: "Go Forward", available: false)
                ShortcutRow(key: "⌘ R", description: "Reload Page", available: false)
                ShortcutRow(key: "⌘ W", description: "Close/Hide Window", available: false)
            } header: {
                Text("Browser Shortcuts")
            } footer: {
                Text("Additional browser shortcuts coming soon")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String
    var available: Bool = true

    var body: some View {
        HStack {
            Text(description)
            Spacer()
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                )
                .foregroundColor(available ? .primary : .secondary)
        }
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "safari")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)

                    Text("Sidebrowser")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("A lightweight floating browser for macOS")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section {
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                LabeledContent("Build") {
                    Text("1")
                        .foregroundColor(.secondary)
                }

                LabeledContent("macOS") {
                    Text("14.0+")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Information")
            }

            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Label("GitHub Repository", systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }

                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
            } header: {
                Text("Support")
            }

            Section {
                HStack {
                    Spacer()
                    Text("Made with ❤️ using SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
