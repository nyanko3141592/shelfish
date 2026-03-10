# Shelfish

> A lightweight file shelf for macOS — drag files to the screen edge to temporarily hold them, then drag them wherever you need.

<!-- TODO: Add demo GIF here -->
<!-- ![Demo](docs/demo.gif) -->

## Quick Start

1. **Download** `Shelfish-v1.0.0-arm64.zip` from [Releases](https://github.com/nyanko3141592/shelfish/releases)
2. **Unzip** and move `Shelfish.app` to `/Applications`
3. **Launch** — a menu bar icon (tray icon) appears. That's it!

> The app is not code-signed. On first launch: right-click → **Open**, or allow in **System Settings → Privacy & Security**.

## How It Works

1. **Drag a file toward the screen edge** — the shelf appears
2. **Drop it** — the file is held on the shelf
3. **Drag it out** to another app or folder — done, the file is removed from the shelf
4. Shelf **auto-hides** when empty

Right-click the menu bar icon to:
- Change shelf position (Left / Right / Top / Bottom)
- Toggle **Launch at Login**
- Quit

## Features

- Auto show/hide on drag
- Icon grid with file names
- Edge-snapped (configurable: left / right / top / bottom)
- Launch at Login (launchd)
- Never steals focus from your current app
- File references only — zero disk overhead
- No Dock icon, menu bar only
- ~50KB, zero dependencies

## Build from Source

Requires macOS 13+ and Swift 5.9+.

```bash
git clone https://github.com/nyanko3141592/shelfish.git
cd shelfish
swift build -c release
.build/release/Shelfish
```

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

See [CLAUDE.md](CLAUDE.md) for detailed architecture notes.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

[MIT](LICENSE)
