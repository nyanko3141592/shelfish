import Cocoa

class ShelfItemView: NSView {
    static let size = NSSize(width: 64, height: 72)

    let item: FileShelfItem
    private let onRemove: (UUID) -> Void
    private var isDragging = false
    private var trackingArea: NSTrackingArea?
    private let removeButton = RemoveButton()

    init(item: FileShelfItem, onRemove: @escaping (UUID) -> Void) {
        self.item = item
        self.onRemove = onRemove
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
        toolTip = item.displayName

        let iconView = NSImageView()
        iconView.image = item.icon
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

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

            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 2),
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
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if isPointInRemoveButton(point) { return }
        guard !isDragging else { return }
        isDragging = true

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(item.url.absoluteString, forType: .fileURL)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let iconImage = item.icon
        iconImage.size = NSSize(width: 32, height: 32)
        draggingItem.setDraggingFrame(bounds, contents: iconImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
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
