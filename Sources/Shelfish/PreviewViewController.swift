import Cocoa
import Quartz

/// Popover content that shows a Quick Look preview of a file. For groups, the
/// left sidebar lists every file and the selection drives the preview. Each
/// sidebar row is also draggable so you can pull individual files out of a
/// group without losing the rest.
class PreviewViewController: NSViewController {
    private let item: FileShelfItem
    private let onRemoveURL: (URL) -> Void
    private let previewView = QLPreviewView()
    private var sidebarStack: NSStackView?
    private var selectedURL: URL?
    private var rowsByURL: [URL: FileRowView] = [:]

    init(item: FileShelfItem, onRemoveURL: @escaping (URL) -> Void) {
        self.item = item
        self.onRemoveURL = onRemoveURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let width: CGFloat = item.isGroup ? 520 : 360
        let height: CGFloat = 300
        view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectURL(item.urls.first)
    }

    private func setupUI() {
        previewView.autostarts = true
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)

        if item.isGroup {
            let sidebar = buildSidebar()
            sidebar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(sidebar)
            self.sidebarStack = sidebar.documentView as? NSStackView

            NSLayoutConstraint.activate([
                sidebar.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                sidebar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
                sidebar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
                sidebar.widthAnchor.constraint(equalToConstant: 180),

                previewView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                previewView.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: 8),
                previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
                previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            ])
        } else {
            NSLayoutConstraint.activate([
                previewView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
                previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
                previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            ])
        }
    }

    private func buildSidebar() -> NSScrollView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.distribution = .fill
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for url in item.urls {
            let row = FileRowView(
                url: url,
                onSelect: { [weak self] url in self?.selectURL(url) },
                onRemove: { [weak self] url in self?.handleRowRemoved(url) }
            )
            rowsByURL[url] = row
            stack.addArrangedSubview(row)
            row.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 4).isActive = true
            row.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -4).isActive = true
        }

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.documentView = stack
        scroll.contentView.postsBoundsChangedNotifications = false

        stack.topAnchor.constraint(equalTo: scroll.contentView.topAnchor).isActive = true
        stack.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: scroll.contentView.trailingAnchor).isActive = true

        return scroll
    }

    private func selectURL(_ url: URL?) {
        guard let url else { return }
        selectedURL = url
        previewView.previewItem = url as QLPreviewItem
        for (rowURL, row) in rowsByURL {
            row.isSelected = (rowURL == url)
        }
    }

    private func handleRowRemoved(_ url: URL) {
        onRemoveURL(url)
    }
}

// MARK: - FileRowView

/// A single row in the group preview sidebar: icon + name. Draggable as a
/// file, selectable, and has a hover-only remove button.
private class FileRowView: NSView {
    let url: URL
    private let onSelect: (URL) -> Void
    private let onRemove: (URL) -> Void
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let removeButton = InlineRemoveButton()
    private var trackingArea: NSTrackingArea?
    private var isHovered = false
    private var isDragging = false
    private var mouseDownLocation: NSPoint?

    var isSelected: Bool = false {
        didSet { updateBackground() }
    }

    init(
        url: URL,
        onSelect: @escaping (URL) -> Void,
        onRemove: @escaping (URL) -> Void
    ) {
        self.url = url
        self.onSelect = onSelect
        self.onRemove = onRemove
        super.init(frame: NSRect(x: 0, y: 0, width: 180, height: 28))
        wantsLayer = true
        layer?.cornerRadius = 5
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 16, height: 16)
        iconView.image = icon
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        nameLabel.stringValue = url.lastPathComponent
        nameLabel.font = .systemFont(ofSize: 11)
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.cell?.truncatesLastVisibleLine = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        removeButton.onClicked = { [weak self] in
            guard let self = self else { return }
            self.onRemove(self.url)
        }
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.isHidden = true
        addSubview(removeButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 26),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -4),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            removeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            removeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 16),
            removeButton.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        removeButton.isHidden = false
        updateBackground()
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        removeButton.isHidden = true
        updateBackground()
    }

    private func updateBackground() {
        if isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
        } else if isHovered {
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
        } else {
            layer?.backgroundColor = nil
        }
    }

    // MARK: - Mouse / drag

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if !removeButton.isHidden && removeButton.frame.contains(point) { return }
        isDragging = false
        mouseDownLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if !removeButton.isHidden && removeButton.frame.contains(point) { return }
        guard !isDragging, let start = mouseDownLocation else { return }
        let dx = event.locationInWindow.x - start.x
        let dy = event.locationInWindow.y - start.y
        guard dx * dx + dy * dy >= 16 else { return }
        isDragging = true

        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.absoluteString, forType: .fileURL)
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let iconImage = NSWorkspace.shared.icon(forFile: url.path)
        iconImage.size = NSSize(width: 32, height: 32)
        draggingItem.setDraggingFrame(bounds, contents: iconImage)
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let wasDragging = isDragging
        let hadMouseDown = mouseDownLocation != nil
        isDragging = false
        mouseDownLocation = nil
        if wasDragging { return }
        if !removeButton.isHidden && removeButton.frame.contains(point) { return }
        if hadMouseDown { onSelect(url) }
    }
}

extension FileRowView: NSDraggingSource {
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
            onRemove(url)
        }
    }
}

// MARK: - InlineRemoveButton

private class InlineRemoveButton: NSView {
    var onClicked: (() -> Void)?
    private let iconSize: CGFloat = 12

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
        let rect = NSRect(
            x: (bounds.width - iconSize) / 2,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        NSColor.secondaryLabelColor.set()
        configured.draw(in: rect)
    }

    override func mouseDown(with event: NSEvent) {
        onClicked?()
    }
}
