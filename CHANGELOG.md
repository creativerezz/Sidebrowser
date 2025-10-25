# Changelog

All notable changes to Sidebrowser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Menu Bar Dropdown Browser** - Converted from floating window to native macOS popover dropdown
  - Popover appears directly below menu bar icon when clicked
  - Auto-dismisses when clicking outside (transient behavior)
  - Smooth slide-down animation
  - Professional menu bar app UX like 1Password or Dropbox
- **Comprehensive Settings Window** with 4 organized tabs:
  - **General Tab**: Homepage configuration, window behavior, size presets
  - **Appearance Tab**: Opacity slider (30-100%), quick presets, theme info
  - **Shortcuts Tab**: Keyboard shortcut reference guide
  - **About Tab**: App information, version details, support links
- **PopoverManager** - Dedicated class for managing menu bar popover lifecycle
- **Window Size Presets** - Quick buttons for Small (400×600), Medium (480×700), Large (600×900)
- **Opacity Quick Presets** - One-click buttons for 50%, 70%, 85%, 95%, 100% opacity
- **Snap to Edges Toggle** - Setting for window edge snapping behavior
- **Reset Position Button** - Quick reset to top-center screen position
- **Keyboard Shortcuts Reference** - Complete list of available shortcuts in settings
- **Support Links** - GitHub repository and issue reporting links

### Changed
- **UI Architecture** - Migrated from floating NSWindow to NSPopover for menu bar integration
- **Window Management** - Removed manual window positioning and tracking code
- **Menu Bar Behavior** - Click icon to toggle dropdown (was: show/hide floating window)
- **App Structure** - Simplified from WindowGroup + Settings to Settings-only Scene
- **FloatingPanelView** - Streamlined to pure SwiftUI content without window accessors
- **MenuBarManager** - Reduced togglePanel() from 37 lines to 8 lines
- **Default Window Size** - Updated to 480×700 (optimized for dropdown)
- **Default Opacity** - Changed from 100% to 95% for subtle transparency
- **Settings Window Size** - Increased to 550×400 for tabbed interface

### Fixed
- **Menu Bar Icon Grayed Out** - Fixed menu items not responding by setting proper targets
- **Settings Window Not Opening** - Added version-specific selectors for macOS 13/14+
- **App Crash on Launch** - Fixed incompatible NSWindow.collectionBehavior flags
  - Removed conflicting `.fullScreenAuxiliary` and `.canJoinAllSpaces` combination
  - Updated to compatible `.canJoinAllSpaces` and `.stationary` flags
- **Window Close Behavior** - Implemented proper hide-instead-of-close for window management
- **Menu Item Targets** - All menu items now properly set their target to enable functionality

### Removed
- **Floating Window System** - Replaced with popover-based approach
- **WindowAccessor** usage in FloatingPanelView
- **FloatingWindowDelegate** class - No longer needed with popover
- **Manual Window Positioning** - Popover handles positioning automatically
- **Window Move Tracking** - Not required for popover implementation
- **CommandGroup** modifiers that interfered with default Settings menu

## [1.0.0] - 2025-10-24

### Added
- Initial release
- Floating browser window with rounded corners and shadow
- Top-center screen positioning
- WebKit-based web browsing
- Navigation controls (back, forward, reload)
- URL bar with search/navigation
- Menu bar integration with system tray icon
- Always on Top toggle
- Opacity control via menu
- Basic settings window
- Window hide/show functionality
- Keyboard shortcuts (⌘L, ⌘T, ⌘,, ⌘Q)

### Technical Details
- Built with SwiftUI and AppKit
- Supports macOS 14.0+
- Uses NSPopover for dropdown UI
- WebKit for rendering web content
- Combine framework for reactive state management

---

## Version History

- **Unreleased** - Menu bar dropdown redesign, comprehensive settings
- **1.0.0** - 2025-10-24 - Initial floating browser release
