import Cocoa

struct FileShelfItem: Identifiable, Equatable {
    let id: UUID
    let urls: [URL]

    init(url: URL) {
        self.id = UUID()
        self.urls = [url]
    }

    init(urls: [URL]) {
        self.id = UUID()
        self.urls = urls
    }

    private init(id: UUID, urls: [URL]) {
        self.id = id
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

    /// Returns a new item with `newURLs` appended, preserving the original id.
    /// Duplicate URLs are filtered out.
    func adding(_ newURLs: [URL]) -> FileShelfItem {
        var combined = self.urls
        let existing = Set(self.urls)
        for url in newURLs where !existing.contains(url) {
            combined.append(url)
        }
        return FileShelfItem(id: self.id, urls: combined)
    }

    /// Returns a new item with `url` removed. Returns nil if the result would be empty.
    func removing(_ url: URL) -> FileShelfItem? {
        let remaining = urls.filter { $0 != url }
        guard !remaining.isEmpty else { return nil }
        return FileShelfItem(id: self.id, urls: remaining)
    }

    static func == (lhs: FileShelfItem, rhs: FileShelfItem) -> Bool {
        lhs.id == rhs.id && lhs.urls == rhs.urls
    }
}
