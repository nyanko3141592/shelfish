import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var shelfWindow: ShelfWindow!
    private var triggerWindow: EdgeTriggerWindow!
    private var hideTimer: Timer?
    private var forceVisible = false
    private var edgePosition: EdgePosition = .load()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        shelfWindow = ShelfWindow(edge: edgePosition)
        shelfWindow.onDragComplete = { [weak self] in
            self?.scheduleHide()
        }

        triggerWindow = EdgeTriggerWindow(edge: edgePosition)
        triggerWindow.onDragEntered = { [weak self] coord in
            self?.showShelf(at: coord)
        }
        triggerWindow.orderFront(nil)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "tray.and.arrow.down",
                accessibilityDescription: "Shelfish"
            )
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleShelf()
        }
    }

    private func toggleShelf() {
        if shelfWindow.isVisible {
            forceVisible = false
            hideShelf()
        } else {
            forceVisible = true
            showShelf(at: nil)
        }
    }

    func showShelf(at coord: CGFloat?) {
        hideTimer?.invalidate()
        hideTimer = nil
        shelfWindow.positionAtEdge(mouseY: coord)
        shelfWindow.animator().alphaValue = 1
        shelfWindow.orderFront(nil)
    }

    func hideShelf() {
        guard !forceVisible else { return }
        hideTimer?.invalidate()
        hideTimer = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            shelfWindow.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            if self?.shelfWindow.alphaValue == 0 {
                self?.shelfWindow.orderOut(nil)
            }
        })
    }

    func scheduleHide() {
        forceVisible = false
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.hideShelf()
        }
    }

    private func changeEdge(_ newEdge: EdgePosition) {
        edgePosition = newEdge
        newEdge.save()

        shelfWindow.orderOut(nil)
        triggerWindow.orderOut(nil)

        shelfWindow = ShelfWindow(edge: newEdge)
        shelfWindow.onDragComplete = { [weak self] in
            self?.scheduleHide()
        }
        shelfWindow.alphaValue = 0

        triggerWindow = EdgeTriggerWindow(edge: newEdge)
        triggerWindow.onDragEntered = { [weak self] coord in
            self?.showShelf(at: coord)
        }
        triggerWindow.orderFront(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let edgeMenu = NSMenu()
        for edge in EdgePosition.allCases {
            let item = NSMenuItem(title: edge.displayName, action: #selector(edgeSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = edge.rawValue
            if edge == edgePosition {
                item.state = .on
            }
            edgeMenu.addItem(item)
        }
        let edgeItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        edgeItem.submenu = edgeMenu
        menu.addItem(edgeItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Shelfish", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func edgeSelected(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let edge = EdgePosition(rawValue: raw) else { return }
        changeEdge(edge)
    }
}
