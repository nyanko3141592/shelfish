import Cocoa

struct FileShelfItem: Identifiable, Equatable {
    let id = UUID()
    let urls: [URL]

    init(url: URL) {
        self.urls = [url]
    }

    init(urls: [URL]) {
        self.urls = urls
    }

    var isGroup: Bool { urls.count > 1 }

    var displayName: String {
        if isGroup {
            return "\(urls.count) items"
        }
        return urls[0].lastPathComponent
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: urls[0].path)
    }

    /// All URLs contained in this item
    var allURLs: Set<URL> {
        Set(urls)
    }

    static func == (lhs: FileShelfItem, rhs: FileShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}
