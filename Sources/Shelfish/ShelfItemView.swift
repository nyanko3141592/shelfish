import Cocoa

class ShelfItemView: NSView {
    static let size = NSSize(width: 72, height: 80)

    let item: FileShelfItem
    private let onRemove: (UUID) -> Void
    private let onClick: ((ShelfItemView) -> Void)?
    private var isDragging = false
    private var mouseDownLocation: NSPoint?
    private var trackingArea: NSTrackingArea?
    private let removeButton = RemoveButton()

    init(
        item: FileShelfItem,
        onRemove: @escaping (UUID) -> Void,
        onClick: ((ShelfItemView) -> Void)? = nil
    ) {
        self.item = item
        self.onRemove = onRemove
        self.onClick = onClick
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        setupUI()
        setupTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 8
        translatesAutoresizingMaskIntoConstraints = false
        toolTip = item.isGroup
            ? item.urls.map { $0.lastPathComponent }.joined(separator: "\n")
            : item.displayName

        // Icon area - use stacked look for groups
        let iconContainer = NSView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconContainer)

        if item.isGroup {
            // Stacked icon effect: show offset shadow copies behind the main icon
            let backIcon = NSImageView()
            backIcon.image = item.urls.count > 1 ? NSWorkspace.shared.icon(forFile: item.urls[1].path) : item.icon
            backIcon.imageScaling = .scaleProportionallyDown
            backIcon.translatesAutoresizingMaskIntoConstraints = false
            backIcon.alphaValue = 0.5
            iconContainer.addSubview(backIcon)

            NSLayoutConstraint.activate([
                backIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor, constant: 4),
                backIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor, constant: -3),
                backIcon.widthAnchor.constraint(equalToConstant: 32),
                backIcon.heightAnchor.constraint(equalToConstant: 32),
            ])
        }

        let iconView = NSImageView()
        iconView.image = item.icon
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        // Badge for group count
        if item.isGroup {
            let badge = CountBadge(count: item.urls.count)
            badge.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(badge)

            NSLayoutConstraint.activate([
                badge.topAnchor.constraint(equalTo: iconContainer.topAnchor, constant: -2),
                badge.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 2),
            ])
        }

        let nameLabel = NSTextField(labelWithString: item.displayName)
        nameLabel.font = .systemFont(ofSize: 9, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.maximumNumberOfLines = 2
        nameLabel.cell?.truncatesLastVisibleLine = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        removeButton.onClicked = { [weak self] in
            guard let self = self else { return }
            self.onRemove(self.item.id)
        }
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.isHidden = true
        addSubview(removeButton)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.size.width),
            heightAnchor.constraint(equalToConstant: Self.size.height),

            iconContainer.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor, constant: item.isGroup ? -2 : 0),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor, constant: item.isGroup ? 2 : 0),
            iconView.widthAnchor.constraint(equalToConstant: item.isGroup ? 32 : 40),
            iconView.heightAnchor.constraint(equalToConstant: item.isGroup ? 32 : 40),

            nameLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),

            // Larger hit target in the top-right corner
            removeButton.topAnchor.constraint(equalTo: topAnchor),
            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 24),
            removeButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    // MARK: - Hover Tracking

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
        removeButton.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = nil
        removeButton.isHidden = true
    }

    // MARK: - Drag Source

    private func isPointInRemoveButton(_ point: NSPoint) -> Bool {
        let buttonFrame = removeButton.frame
        return !removeButton.isHidden && buttonFrame.contains(point)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isPointInRemoveButton(point) {
            // Let the remove button handle it
            return
        }
        isDragging = false
        mouseDownLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isPointInRemoveButton(point) { return }
        guard !isDragging else { return }
        guard let start = mouseDownLocation else { return }

        let dx = event.locationInWindow.x - start.x
        let dy = event.locationInWindow.y - start.y
        // Require a small movement before starting drag — otherwise a click with
        // a tiny jitter would immediately turn into a drag session.
        guard dx * dx + dy * dy >= 16 else { return }

        isDragging = true

        var draggingItems: [NSDraggingItem] = []
        for url in item.urls {
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(url.absoluteString, forType: .fileURL)

            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            let iconImage = NSWorkspace.shared.icon(forFile: url.path)
            iconImage.size = NSSize(width: 40, height: 40)
            draggingItem.setDraggingFrame(bounds, contents: iconImage)
            draggingItems.append(draggingItem)
        }

        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let wasDragging = isDragging
        let hadMouseDown = mouseDownLocation != nil
        isDragging = false
        mouseDownLocation = nil

        if wasDragging || isPointInRemoveButton(point) { return }
        guard hadMouseDown else { return }

        onClick?(self)
    }
}

// MARK: - RemoveButton (custom view with large hit area)

private class RemoveButton: NSView {
    var onClicked: (() -> Void)?
    private let iconSize: CGFloat = 14

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let image = NSImage(
            systemSymbolName: "xmark.circle.fill",
            accessibilityDescription: "Remove"
        ) else { return }

        let config = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
        let configured = image.withSymbolConfiguration(config) ?? image

        // Draw icon centered in the top-right area
        let x = bounds.maxX - iconSize - 2
        let y = bounds.maxY - iconSize - 2
        let rect = NSRect(x: x, y: y, width: iconSize, height: iconSize)

        NSColor.secondaryLabelColor.set()
        configured.draw(in: rect)
    }

    override func mouseDown(with event: NSEvent) {
        onClicked?()
    }
}

// MARK: - CountBadge

private class CountBadge: NSView {
    private let count: Int

    init(count: Int) {
        self.count = count
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        let text = "\(count)"
        let width = max(16, CGFloat(text.count) * 7 + 8)
        return NSSize(width: width, height: 16)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let path = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        NSColor.controlAccentColor.setFill()
        path.fill()

        let text = "\(count)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        let size = text.size(withAttributes: attrs)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        text.draw(at: point, withAttributes: attrs)
    }
}

// MARK: - NSDraggingSource

extension ShelfItemView: NSDraggingSource {
    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        context == .outsideApplication ? .copy : .move
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        if operation != [] {
            onRemove(item.id)
        }
    }
}
