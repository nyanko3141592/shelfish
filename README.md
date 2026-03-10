# Shelfish

A lightweight, open-source file shelf for macOS. Temporarily hold files via drag and drop, then drag them wherever you need.

## Features

- **Auto show/hide** — Shelf appears only when you drag a file to the screen edge, then auto-hides when empty
- **Icon view** — Clean icon grid with file names; hover for full name tooltip
- **Edge-snapped** — Shelf sits flush against the screen edge (right by default)
- **Configurable position** — Choose Left / Right / Top / Bottom from the menu
- **Launch at Login** — Optional auto-start via launchd
- **Drag in** — Drop files from Finder or any app onto the shelf
- **Drag out** — Drag files from the shelf to any destination; auto-removed after drop
- **Always on top** — Floating panel stays visible across all Spaces
- **Zero overhead** — Stores only file references, never copies files
- **Menu bar app** — No Dock icon clutter

## Install

### Download

Grab `Shelfish-v1.0.0-arm64.zip` from the [Releases](https://github.com/nyanko3141592/shelfish/releases) page, unzip, and move `Shelfish.app` to `/Applications`.

> **Note:** The app is not code-signed. On first launch, right-click the app → **Open**, or allow it in **System Settings → Privacy & Security**.

### Build from source

Requires macOS 13+ and Swift 5.9+.

```bash
git clone https://github.com/nyanko3141592/shelfish.git
cd shelfish
swift build -c release
```

The binary is at `.build/release/Shelfish`. To create an app bundle, see the release workflow.

## Usage

1. Launch Shelfish — a menu bar icon appears, the shelf is hidden by default
2. **Drag a file toward the screen edge** — the shelf appears near your cursor
3. **Drop files onto the shelf** to temporarily hold them
4. **Drag files out** to use them — they are automatically removed after a successful drop
5. **Hover over an icon** to see the full file name; click **X** to remove manually
6. The shelf **auto-hides** when all files are removed
7. **Click the menu bar icon** to force toggle visibility
8. **Right-click the menu bar icon** to access settings:
   - **Position** — Left / Right / Top / Bottom
   - **Launch at Login** — Toggle auto-start at login
   - **Quit Shelfish**

## Architecture

Pure Swift/AppKit, built with Swift Package Manager. No XIBs, no Storyboards, no external dependencies.

```
Sources/Shelfish/
├── main.swift                # App entry point
├── AppDelegate.swift         # Menu bar icon, show/hide, settings menu
├── EdgePosition.swift        # Edge enum (left/right/top/bottom) + persistence
├── LaunchAtLogin.swift       # launchd LaunchAgent management
├── ShelfWindow.swift         # Compact edge-snapped floating NSPanel
├── ShelfViewController.swift # Drop zone + icon grid layout
├── ShelfItemView.swift       # File icon tile with drag source + remove button
├── EdgeTriggerWindow.swift   # Invisible edge zone that detects incoming drags
└── FileShelfItem.swift       # File reference model
```

### Key design decisions

- **Edge-snapped, not floating** — The shelf is flush against the chosen screen edge, positioned near the cursor. No manual positioning needed.
- **Auto show/hide** — A thin invisible trigger zone at the screen edge detects file drags. The shelf fades in and auto-hides when empty.
- **Icon grid** — Compact icon-based display with truncated file names. Full name shown via tooltip on hover.
- **`NSPanel` with `.nonactivatingPanel`** — Never steals focus from your current app.
- **File references only** — Holds URLs, not copies. Zero disk overhead.
- **launchd for auto-start** — Creates/removes `~/Library/LaunchAgents/com.shelfish.app.plist`. No login items API or SMAppService needed.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

[MIT](LICENSE)
