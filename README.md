# Shelfish

A lightweight, open-source file shelf for macOS. Temporarily hold files via drag and drop, then drag them wherever you need.

## Features

- **Auto show/hide** — Shelf appears only when you drag a file to the screen edge, then auto-hides when empty
- **Icon view** — Clean icon grid instead of a cluttered file list; hover for file name tooltip
- **Edge-snapped** — Shelf sits flush against the screen edge (right by default)
- **Configurable position** — Right-click the menu bar icon to choose Left / Right / Top / Bottom
- **Drag in** — Drop files from Finder or any app onto the shelf
- **Drag out** — Drag files from the shelf to any destination; auto-removed after drop
- **Always on top** — Floating panel stays visible across all Spaces
- **Zero overhead** — Stores only file references, never copies files
- **Menu bar app** — No Dock icon clutter

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+

## Build & Run

```bash
swift build
.build/debug/Shelfish
```

Release build:

```bash
swift build -c release
.build/release/Shelfish
```

## Usage

1. Launch Shelfish — a menu bar icon appears, the shelf is hidden
2. **Drag a file toward the screen edge** — the shelf appears
3. **Drop files onto the shelf** to temporarily hold them
4. **Drag files out** to use them — they are automatically removed after drop
5. **Hover over an icon** to see the file name; click **X** to remove manually
6. The shelf **auto-hides** when all files are removed
7. **Click the menu bar icon** to force toggle visibility
8. **Right-click the menu bar icon** to change position (Left / Right / Top / Bottom) or quit

## Architecture

Pure Swift/AppKit, built with Swift Package Manager. No XIBs, no Storyboards.

```
Sources/Shelfish/
├── main.swift                # App entry point
├── AppDelegate.swift         # Menu bar icon, show/hide, settings
├── EdgePosition.swift        # Edge enum (left/right/top/bottom) + persistence
├── ShelfWindow.swift         # Edge-snapped floating NSPanel
├── ShelfViewController.swift # Drop zone + icon grid layout
├── ShelfItemView.swift       # File icon tile with drag source + remove button
├── EdgeTriggerWindow.swift   # Invisible edge zone that detects incoming drags
└── FileShelfItem.swift       # File reference model
```

### Key design decisions

- **Edge-snapped, not floating** — The shelf is flush against the chosen screen edge. No manual positioning needed.
- **Auto show/hide** — A thin invisible trigger zone at the screen edge detects file drags. The shelf fades in and auto-hides when empty.
- **Icon grid** — Compact icon-based display instead of a file list. File names shown via tooltip on hover.
- **`NSPanel` with `.nonactivatingPanel`** — Never steals focus from your current app.
- **File references only** — Holds URLs, not copies. Zero disk overhead.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

[MIT](LICENSE)
