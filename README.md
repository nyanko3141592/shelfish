<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="Shelfish App Icon">
</p>

<h1 align="center">Shelfish</h1>

<p align="center">
  <strong>A lightweight file shelf for macOS</strong><br>
  Drag files to the screen edge to temporarily hold them, then drop them wherever you need.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple&logoColor=white" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="MIT License">
  <img src="https://img.shields.io/badge/Size-~50KB-green" alt="~50KB">
</p>

<p align="center">
  <a href="README_ja.md">日本語</a>
</p>

---

<!-- TODO: Add demo GIF -->
<!-- <p align="center"><img src="docs/demo.gif" width="600" alt="Demo"></p> -->

## How It Works

1. **Drag a file toward the screen edge** — the shelf slides into view
2. **Drop it on the shelf** — the file is held there temporarily
3. **Drag it out** to another app or folder — done, the shelf auto-hides

<br>

## Features

| | Feature | |
|---|---|---|
| :open_file_folder: | **Auto show/hide** — shelf appears on drag, hides when empty | |
| :round_pushpin: | **Edge-snapped** — left, right, top, or bottom of your screen | |
| :rocket: | **Launch at Login** — starts silently via launchd | |
| :ghost: | **Invisible presence** — no Dock icon, menu bar only, never steals focus | |
| :feather: | **Tiny footprint** — ~50KB, zero dependencies, file references only | |
| :framed_picture: | **Icon grid** — shows file icons and names at a glance | |

<br>

## Quick Start

1. **Download** the latest `Shelfish-v1.0.0-arm64.zip` from [Releases](https://github.com/nyanko3141592/shelfish/releases)
2. **Unzip** and move `Shelfish.app` to `/Applications`
3. **Launch** — a menu bar icon appears. That's it!

> [!NOTE]
> The app is not code-signed. On first launch, right-click the app and select **Open**, or allow it in **System Settings > Privacy & Security**.

### Menu Bar Options

Right-click the menu bar icon to:
- Change shelf position (Left / Right / Top / Bottom)
- Toggle **Launch at Login**
- Quit

<br>

## Build from Source

Requires **macOS 13+** and **Swift 5.9+**.

```bash
git clone https://github.com/nyanko3141592/shelfish.git
cd shelfish
swift build -c release
.build/release/Shelfish
```

<br>

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

<br>

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

[MIT](LICENSE)
