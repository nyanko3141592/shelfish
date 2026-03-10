# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
swift build              # Debug build → .build/debug/Shelfish
swift build -c release   # Release build → .build/release/Shelfish
```

No external dependencies. Pure Swift/AppKit, targeting macOS 13+, Swift 5.9+.

## Running

```bash
.build/debug/Shelfish    # Run directly (menu bar app, no Dock icon)
```

The app requires a GUI environment. It registers as `.accessory` (no Dock icon) and creates floating `NSPanel` windows.

## Release

Tag-based: `git tag v1.2.3 && git push --tags` triggers the release workflow which builds, bundles into `.app`, and uploads to GitHub Releases.

## Architecture

**AppDelegate** is the central orchestrator. It owns two windows and a status bar item:

1. **EdgeTriggerWindow** — An invisible 24px `NSPanel` at the configured screen edge. When a file drag enters this zone, it calls back to AppDelegate to show the shelf.
2. **ShelfWindow** — A compact floating `NSPanel` (80×360) that appears near the cursor position. Contains a `ShelfViewController`.

**Data flow:**
- Drag-in: `EdgeTriggerWindow` detects drag → `AppDelegate.showShelf()` → `DropZoneView` (in ShelfViewController) receives drop → creates `FileShelfItem` (URL reference only) → adds `ShelfItemView` to stack
- Drag-out: `ShelfItemView` (NSDraggingSource) starts drag session → on successful drop, removes itself → when shelf is empty, `AppDelegate.scheduleHide()` fades out after 1.5s

**Key patterns:**
- All windows use `.nonactivatingPanel` to never steal focus
- `EdgePosition` enum (left/right/top/bottom) persisted via UserDefaults
- `LaunchAtLogin` manages `~/Library/LaunchAgents/com.shelfish.app.plist` directly
- Callbacks flow upward via closures (ShelfItemView → ShelfViewController → ShelfWindow → AppDelegate)
- Files are stored as URL references, never copied

**Pasteboard types:** Both `.fileURL` and legacy `NSFilenamesPboardType` are registered for Finder compatibility.
