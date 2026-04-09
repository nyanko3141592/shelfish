import Cocoa

class ShelfWindow: NSPanel {
    private static let shelfWidth: CGFloat = 88
    private static let shelfHeight: CGFloat = 360

    let edge: EdgePosition
    var onDragComplete: (() -> Void)?

    init(edge: EdgePosition) {
        self.edge = edge
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.shelfWidth, height: Self.shelfHeight),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isReleasedWhenClosed = false
        alphaValue = 0

        let viewController = ShelfViewController(edge: edge)
        viewController.onDragComplete = { [weak self] in
            self?.onDragComplete?()
        }
        contentViewController = viewController

        positionAtEdge(mouseY: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    override var canBecomeKey: Bool { true }

    /// Position the shelf at the configured edge, optionally centered on a Y coordinate
    func positionAtEdge(mouseY: CGFloat?, on screen: NSScreen? = nil) {
        guard let screen = screen ?? NSScreen.main else { return }
        let sf = screen.visibleFrame

        let w: CGFloat
        let h: CGFloat
        if edge.isVertical {
            w = Self.shelfWidth
            h = Self.shelfHeight
        } else {
            w = Self.shelfHeight
            h = Self.shelfWidth
        }

        var x: CGFloat
        var y: CGFloat

        switch edge {
        case .right:
            x = sf.maxX - w
            y = clampY(mouseY, shelfHeight: h, in: sf)
        case .left:
            x = sf.origin.x
            y = clampY(mouseY, shelfHeight: h, in: sf)
        case .top:
            x = clampX(mouseY, shelfWidth: w, in: sf)
            y = sf.maxY - h
        case .bottom:
            x = clampX(mouseY, shelfWidth: w, in: sf)
            y = sf.origin.y
        }

        setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
    }

    private func clampY(_ mouseY: CGFloat?, shelfHeight h: CGFloat, in sf: NSRect) -> CGFloat {
        let centerY = mouseY ?? (sf.midY)
        return min(max(centerY - h / 2, sf.origin.y), sf.maxY - h)
    }

    private func clampX(_ mouseX: CGFloat?, shelfWidth w: CGFloat, in sf: NSRect) -> CGFloat {
        let centerX = mouseX ?? (sf.midX)
        return min(max(centerX - w / 2, sf.origin.x), sf.maxX - w)
    }

    @objc private func screenDidChange(_ notification: Notification) {
        positionAtEdge(mouseY: nil)
    }
}
