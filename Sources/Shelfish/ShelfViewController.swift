import Cocoa

class ShelfViewController: NSViewController {
    private var items: [FileShelfItem] = []
    private let scrollView = NSScrollView()
    private let iconContainer = NSStackView()
    private let emptyLabel = NSTextField(labelWithString: "Drop here")
    private let edge: EdgePosition
    private let previewPopover = NSPopover()
    private weak var previewAnchorView: NSView?
    var onDragComplete: (() -> Void)?

    init(edge: EdgePosition) {
        self.edge = edge
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let dropZone = DropZoneView()
        dropZone.onDrop = { [weak self] urls in
            self?.handleDroppedURLs(urls)
        }
        view = dropZone
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.15).cgColor

        // Visual effect for frosted glass look
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualEffect, positioned: .below, relativeTo: nil)

        let isVertical = edge.isVertical

        iconContainer.orientation = isVertical ? .vertical : .horizontal
        iconContainer.spacing = 4
        iconContainer.alignment = isVertical ? .centerX : .centerY
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = iconContainer
        scrollView.hasVerticalScroller = isVertical
        scrollView.hasHorizontalScroller = !isVertical
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        emptyLabel.font = .systemFont(ofSize: 11, weight: .medium)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        if isVertical {
            iconContainer.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor).isActive = true
            iconContainer.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor).isActive = true
            iconContainer.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
        } else {
            iconContainer.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
            iconContainer.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor).isActive = true
            iconContainer.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor).isActive = true
        }

        updateEmptyState()
    }

    private func handleDroppedURLs(_ urls: [URL]) {
        // Filter out URLs that already exist in any item
        let existingURLs = items.reduce(into: Set<URL>()) { $0.formUnion($1.allURLs) }
        let newURLs = urls.filter { !existingURLs.contains($0) }
        guard !newURLs.isEmpty else { return }

        // Merge into the first existing item so everything lives in one bundle,
        // then you can pull the whole bundle out at once or open any single file
        // from the preview popover.
        if let first = items.first {
            let merged = first.adding(newURLs)
            replaceItem(at: 0, with: merged)
        } else {
            let item = newURLs.count == 1
                ? FileShelfItem(url: newURLs[0])
                : FileShelfItem(urls: newURLs)
            addItem(item)
        }
    }

    func addItem(_ item: FileShelfItem) {
        items.append(item)
        iconContainer.addArrangedSubview(makeItemView(for: item))
        updateEmptyState()
    }

    private func replaceItem(at index: Int, with newItem: FileShelfItem) {
        let oldView = iconContainer.arrangedSubviews[index]
        iconContainer.removeArrangedSubview(oldView)
        oldView.removeFromSuperview()

        items[index] = newItem
        let newView = makeItemView(for: newItem)
        iconContainer.insertArrangedSubview(newView, at: index)

        // If a preview was open for this item, refresh it with the new contents
        if previewPopover.isShown {
            previewPopover.performClose(nil)
            showPreview(for: newItem, near: newView)
        }
    }

    private func makeItemView(for item: FileShelfItem) -> ShelfItemView {
        ShelfItemView(
            item: item,
            onRemove: { [weak self] id in
                self?.removeItem(id: id)
            },
            onClick: { [weak self] view in
                self?.handleItemClicked(view)
            }
        )
    }

    func removeItem(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if previewPopover.isShown {
            previewPopover.performClose(nil)
        }
        items.remove(at: index)
        let itemView = iconContainer.arrangedSubviews[index]
        iconContainer.removeArrangedSubview(itemView)
        itemView.removeFromSuperview()
        updateEmptyState()

        if items.isEmpty {
            onDragComplete?()
        }
    }

    /// Remove a single URL from the item. If it was the last URL, remove the item entirely.
    func removeURL(_ url: URL, fromItem id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if let updated = items[index].removing(url) {
            replaceItem(at: index, with: updated)
        } else {
            removeItem(id: id)
        }
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !items.isEmpty
    }

    // MARK: - Preview

    private func handleItemClicked(_ view: ShelfItemView) {
        if previewPopover.isShown && previewAnchorView === view {
            previewPopover.performClose(nil)
            return
        }
        showPreview(for: view.item, near: view)
    }

    private func showPreview(for item: FileShelfItem, near anchor: NSView) {
        if previewPopover.isShown {
            previewPopover.performClose(nil)
        }

        let preview = PreviewViewController(item: item) { [weak self] url in
            self?.removeURL(url, fromItem: item.id)
        }
        previewPopover.contentViewController = preview
        previewPopover.behavior = .transient
        previewPopover.animates = true
        previewAnchorView = anchor

        let preferredEdge: NSRectEdge
        switch edge {
        case .right: preferredEdge = .minX
        case .left: preferredEdge = .maxX
        case .top: preferredEdge = .maxY
        case .bottom: preferredEdge = .minY
        }
        previewPopover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: preferredEdge)
    }
}

// MARK: - DropZoneView

class DropZoneView: NSView {
    var onDrop: (([URL]) -> Void)?

    private static let filenamesPboardType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        registerForDraggedTypes([.fileURL, Self.filenamesPboardType])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let canRead = sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
        if canRead {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
            return .copy
        }
        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        layer?.backgroundColor = nil
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        layer?.backgroundColor = nil

        guard let urls = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else { return false }

        onDrop?(urls)
        return true
    }
}
