import Cocoa

class EdgeTriggerWindow: NSPanel {
    private static let triggerThickness: CGFloat = 24

    var onDragEntered: ((CGFloat) -> Void)?
    private var currentEdge: EdgePosition = .right

    /// Legacy pasteboard type used by Finder
    private static let filenamesPboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

    init(edge: EdgePosition) {
        self.currentEdge = edge
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        isReleasedWhenClosed = false

        let triggerView = TriggerView()
        triggerView.onDragEntered = { [weak self] point in
            guard let self = self else { return }
            let screenPoint = self.convertPoint(toScreen: point)
            let coord = self.currentEdge.isVertical ? screenPoint.y : screenPoint.x
            self.onDragEntered?(coord)
        }
        contentView = triggerView

        positionAtEdge(edge)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func positionAtEdge(_ edge: EdgePosition) {
        currentEdge = edge
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let t = Self.triggerThickness

        let frame: NSRect
        switch edge {
        case .right:
            frame = NSRect(x: sf.maxX - t, y: sf.origin.y, width: t, height: sf.height)
        case .left:
            frame = NSRect(x: sf.origin.x, y: sf.origin.y, width: t, height: sf.height)
        case .top:
            frame = NSRect(x: sf.origin.x, y: sf.maxY - t, width: sf.width, height: t)
        case .bottom:
            frame = NSRect(x: sf.origin.x, y: sf.origin.y, width: sf.width, height: t)
        }
        setFrame(frame, display: true)
    }

    @objc private func screenDidChange(_ notification: Notification) {
        positionAtEdge(currentEdge)
    }
}

// MARK: - TriggerView

private class TriggerView: NSView {
    var onDragEntered: ((NSPoint) -> Void)?

    private static let filenamesPboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([
            .fileURL,
            Self.filenamesPboardType,
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pb = sender.draggingPasteboard
        let hasFiles = pb.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) || pb.types?.contains(Self.filenamesPboardType) == true

        if hasFiles {
            let location = sender.draggingLocation
            onDragEntered?(location)
            return .copy
        }
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        false
    }
}
